# Gophish on AWS: 全体アーキテクチャと構築ガイド

この設計は、AWS上にGophish（フィッシングシミュレーションツール）をデプロイするための、セキュリティと自動化を考慮したTerraformプロジェクトです。

## 1. 全体アーキテクチャ概要

```
(インターネット)
      |
      |---------------------------------------------------|
      | (Route 53)                                        |
      | gophish.yourdomain.com -> A -> EC2 Public IP        |
      | phish.yourdomain.com   -> A -> EC2 Public IP        |
      | (SPF, DKIM, DMARC レコード for yourdomain.com)      |
      |---------------------------------------------------|
      |                                                   | (Amazon SES)
      |                                                   |   - メール送信
      |                                                   |   - ドメイン認証
      |                                                   |
(AWS Cloud)                                                |
      |                                                   |
      |--> [VPC]                                          |
            |--> [Public Subnet]                           |
                  |--> [EC2 Instance (Amazon Linux 2)] <--- [Security Group]
                        |  (user_dataでプロビジョニング)      (Admin: 3333, Phish: 80/443)
                        |  - Docker, Docker Compose, Certbot, EFS Utils
                        |  - IAM Role (SSM, Secrets Manager, CloudWatch Logs, S3)
                        |
                        |--> [Docker Container: gophish]
                              |  - Logs -> CloudWatch Logs
                              |  - Logs -> S3 (Session Manager)
                              |
                              |--> [EFS Mount Point]
                                    | - gophish.db
                                    | - config.json
                                    | - Let's Encrypt certificates
            |--> [VPC Endpoints]
                  | - SSM, SSMMessages, EC2Messages (for Session Manager)
```

## 2. 主要技術スタック

*   **インフラストラクチャ・アズ・コード (IaC):** Terraform
*   **コンテナ化:** Docker, Docker Compose
*   **クラウドプロバイダー:** Amazon Web Services (AWS)
*   **OS:** Amazon Linux 2
*   **メール送信:** Amazon SES
*   **DNS管理:** AWS Route 53
*   **SSL/TLS:** Let's Encrypt (Certbot)
*   **アクセス管理:** AWS Systems Manager Session Manager
*   **ストレージ:**
    *   **EBS (Elastic Block Store):** EC2インスタンスのOSやアプリケーションのバイナリを格納するルートボリュームとして使用し、インスタンスの起動と動作を支えます。
    *   **EFS (Elastic File System):** Gophishのデータベースや設定ファイル、証明書などのアプリケーションデータを永続化し、EC2インスタンスのライフサイクルとは独立してデータを保護します。

## 3. セキュリティとロギング

*   **EC2アクセス:** SSHポートをインターネットに公開せず、AWS Systems Manager Session Manager を利用して安全にアクセスします。
*   **セッションログ:** Session Managerのターミナル操作は、すべてAmazon S3とCloudWatch Logsに自動的に保存され、監査証跡として利用可能です。
*   **SSL/TLS:** Gophish管理画面およびフィッシングサイトはLet's EncryptによるHTTPSで保護されます。
*   **メール認証:** Amazon SESと連携し、SPF, DKIM, DMARCを設定することで、メールの信頼性と到達率を向上させます。
*   **静的解析:** [Checkov](https://www.checkov.io/) を導入し、Terraformコードのセキュリティとベストプラクティスを継続的に検査しています。

## 4. 構築手順

Terraformによる自動化されたデプロイと、その後に続く手動設定のステップを以下に示します。

### フェーズ1：構築前の準備 (Terraform実行前)

1.  **AWS認証情報の設定**
    *   **内容:** Terraformを実行する環境で、AWSにアクセスするための認証情報（アクセスキー、シークレットキー）を設定します。
    *   **方法:** `aws configure` コマンドで設定するのが一般的です。

2.  **Terraformバックエンドの作成**
    *   **内容:** Terraformの状態（state）を管理するS3バケットとDynamoDBテーブルを**手動で作成**します。これにより、複数人での作業や状態の安全な保持が可能になります。
    *   **作業:**
        1.  一意な名前でS3バケットを1つ作成します。（例: `my-gophish-tfstate-bucket`）
        2.  パーティションキーが `LockID` (文字列型) のDynamoDBテーブルを1つ作成します。（例: `my-gophish-tfstate-lock`）
        3.  `terraform/main.tf` の `backend "s3"` ブロックのコメントを解除し、作成したバケット名とテーブル名に書き換えます。

3.  **アクセス元IPアドレスとドメインの設定**
    *   **内容:** Gophishの管理画面にアクセスするご自身のグローバルIPアドレスと、利用するドメイン名を設定します。
    *   **作業:** `terraform/terraform.tfvars.example` を `terraform.tfvars` という名前でコピーし、`my_ip` と `domain_name` の値を環境に合わせて書き換えてください。

### フェーズ2：Terraform実行とドメイン設定

1.  **Terraformの実行**
    *   **作業:** `terraform` ディレクトリ内で `terraform init` -> `terraform plan` -> `terraform apply` を実行します。
    *   **注意点:** `terraform apply` を実行すると、`terraform.tfvars` で指定したドメインがRoute 53に登録されます。**ドメイン登録には費用が発生**し、一度登録すると最低1年間は契約が継続されます。また、登録者情報のメールアドレスに認証メールが送信されるため、**14日以内に認証を完了しないとドメインが失効する**可能性があります。

### フェーズ3：初回サーバー設定 (EC2インスタンスへの初回ログイン後)

1.  **EC2への接続**
    *   **方法:** AWSコンソールのEC2画面からインスタンスを選択し、「接続」→「セッションマネージャー」で接続します。SSHキーは不要です。

2.  **EFSファイルシステムのマウント**
    *   **内容:** Gophishのデータベースや設定ファイルを永続化するため、EFSをEC2にマウントします。
    *   **作業:**
        ```bash
        # マウントポイント作成
        sudo mkdir /efs
        
        # EFSをマウント (EFSのIDはAWSコンソールで確認)
        sudo mount -t efs fs-xxxxxxxx:/ /efs
        
        # 永続化のためfstabに追記
        echo "fs-xxxxxxxx:/ /efs efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
        ```

3.  **SSL証明書の取得**
    *   **作業:** Let's Encryptの証明書を初めて取得します。`gophish.yourdomain.com` の部分はご自身のドメインに置き換えてください。
        ```bash
        sudo certbot certonly --standalone -d gophish.yourdomain.com -d phish.yourdomain.com
        ```

4.  **Gophishの起動とパスワード取得**
    *   **作業:**
        ```bash
        # Docker Composeで起動
        cd /efs
        sudo docker-compose up -d
        
        # 初回パスワードをログから確認 (起動後、少し待ってから実行)
        sudo docker-compose logs gophish
        ```
    *   ログの中に表示される初期パスワードを控えて、Gophish管理画面 (`https://gophish.yourdomain.com:3333`) にログインし、すぐにパスワードを変更してください。

5.  **SSL証明書の自動更新設定**
    *   **作業:** `crontab` に `certbot renew` を登録し、証明書が自動で更新されるようにします。
        ```bash
        sudo crontab -e
        # エディタで以下の行を追加
        0 1 * * * /usr/bin/certbot renew --quiet
        ```

### フェーズ4：AWSサービス連携の最終設定

1.  **SESのサンドボックス解除 (最重要)**
    *   **内容:** デフォルト状態のSESは「サンドボックス」モードであり、**検証済みのメールアドレスにしかメールを送信できません。**
    *   **作業:** AWSサポートに「SES Sending Limits Increase」のケースを起票し、サンドボックス解除を申請してください。利用目的（フィッシング訓練であること）を明確に伝える必要があります。

2.  **Session Managerのログ記録有効化**
    *   **内容:** EC2へのターミナル操作ログをS3とCloudWatchに保存する設定を有効化します。
    *   **作業:** Systems Managerの「セッションマネージャー」設定画面で、S3とCloudWatch Logsへのロギングを有効にし、Terraformで作成したリソース（バケット、ロググループ）を選択します。


