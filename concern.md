はい、承知いたしました。
Terraformコードだけでは完結しない、本番環境として利用するために必要な手作業や注意点を以下にまとめます。

---

### Gophish環境構築 最終チェックリスト

このリストは、`terraform apply` を実行する前、実行後、そしてサーバーに初めてログインした後の手作業を時系列で示しています。

#### フェーズ1：構築前の準備 (Terraform実行前)

1.  **AWS認証情報の設定:**
    *   **内容:** Terraformを実行する環境で、AWSにアクセスするための認証情報（アクセスキー、シークレットキー）が設定されている必要があります。
    *   **方法:** `aws configure` コマンドで設定するのが一般的です。

2.  **Terraformバックエンドの作成:**
    *   **内容:** Terraformの状態を管理するS3バケットとDynamoDBテーブルを**手動で作成**する必要があります。
    *   **注意点:** これらはTerraformの管理外で、`terraform init` を実行する前に存在している必要があります。
    *   **作業:**
        1.  一意な名前でS3バケットを1つ作成します。
        2.  パーティションキーが `LockID` (文字列型) のDynamoDBテーブルを1つ作成します。
        3.  `terraform/main.tf` の `backend "s3"` ブロックのコメントを解除し、作成したバケット名とテーブル名に書き換えます。

3.  **アクセス元IPアドレスの設定:**
    *   **内容:** 管理画面にアクセスするご自身のグローバルIPアドレスを設定します。
    *   **作業:** `terraform/terraform.tfvars.example` を `terraform.tfvars` という名前でコピーし、`my_ip` の値を ` "xxx.xxx.xxx.xxx/32" ` の形式でご自身のIPアドレスに書き換えてください。

#### フェーズ2：Terraform実行とドメイン設定

1.  **ドメインの取得 (Route 53):**
    *   **内容:** Gophishで使用するドメインをAWS Route 53で取得します。
    *   **作業:** AWSコンソールのRoute 53サービスにアクセスし、「ドメインの登録」から希望するドメイン名を取得してください。この作業はTerraformの実行前に行う必要があります。
    *   **注意点:** ドメイン取得には数分〜数時間かかる場合があります。

2.  **Terraformの実行:**
    *   **作業:** `terraform` ディレクトリ内で `terraform init` -> `terraform plan` -> `terraform apply` を実行します。
    *   **注意点:** `terraform apply` 実行後、Route 53のホストゾーンが作成され、必要なDNSレコードが自動的に設定されます。

#### フェーズ3：初回サーバー設定 (EC2インスタンスへの初回ログイン後)

1.  **EC2への接続:**
    *   **方法:** AWSコンソールのEC2画面からインスタンスを選択し、「接続」→「セッションマネージャー」で接続します。

2.  **EFSファイルシステムのマウント:**
    *   **内容:** Gophishのデータを永続化するため、EFSをEC2にマウントします。
    *   **作業:**
        ```bash
        # マウントポイント作成
        sudo mkdir /efs
        
        # EFSをマウント (EFSのIDはAWSコンソールで確認)
        sudo mount -t efs fs-xxxxxxxx:/ /efs
        
        # 永続化のためfstabに追記
        echo "fs-xxxxxxxx:/ /efs efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
        ```

3.  **各種ファイル作成:**
    *   **作業:** マウントしたEFS上に、`docker-compose.yml` と `config.json` を作成します。

4.  **SSL証明書の取得:**
    *   **作業:** Let's Encryptの証明書を初めて取得します。
        ```bash
        sudo certbot certonly --standalone -d gophish.ponponboo.com -d phish.ponponboo.com
        ```

5.  **Gophish設定ファイルの編集:**
    *   **内容:** `/efs/config.json` を編集し、TLSを有効化します。`use_tls` を `true` にし、`cert_path` と `key_path` に上記で取得した証明書へのパス (`/etc/letsencrypt/live/gophish.ponponboo.com/fullchain.pem` など) を記述します。

6.  **Gophishの起動とパスワード取得:**
    *   **作業:**
        ```bash
        # Docker Composeで起動
        cd /efs
        sudo docker-compose up -d
        
        # 初回パスワードをログから確認
        sudo docker logs gophish 
        ```

7.  **SSL証明書の自動更新設定:**
    *   **作業:** `crontab` に `certbot renew` を登録し、証明書が自動で更新されるようにします。

#### フェーズ4：AWSサービス連携の最終設定

1.  **SESのサンドボックス解除 (最重要):**
    *   **内容:** デフォルト状態のSESは「サンドボックス」モードであり、**検証済みのメールアドレスにしかメールを送信できません。**
    *   **作業:** AWSサポートに「SES Sending Limits Increase」のケースを起票し、サンドボックス解除を申請してください。利用目的（フィッシング訓練であること）を明確に伝える必要があります。

2.  **Session Managerのログ記録有効化:**
    *   **内容:** EC2へのターミナル操作ログをS3とCloudWatchに保存する設定を有効化します。
    *   **作業:** Systems Managerの「セッションマネージャー」設定画面で、S3とCloudWatch Logsへのロギングを有効にし、Terraformで作成したリソース（バケット、ロググループ）を選択します。

3.  **Gophish WebUIでのSMTP設定:**
    *   **内容:** GophishのWebUIからSMTPサーバーの設定を行います。
    *   **作業:** `terraform apply` 実行後に出力される `ses_smtp_endpoint` と `ses_smtp_ports` の情報を使用して、GophishのWebUIでSMTPサーバーを設定してください。SMTP認証情報（ユーザー名とパスワード）は、SESコンソールで作成したものを手動で入力する必要があります。

---

以上が、コード実行以外に必要なすべての作業と注意点です。特に **SESのサンドボックス解除** は見落としがちですが、実際のキャンペーンを行うためには必須の作業となります。