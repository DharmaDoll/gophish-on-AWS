承知いたしました。これまでの議論を踏まえ、Gophish環境の全体のアーキテクチャと仕様をまとめます。

---

### Gophish on AWS: 全体アーキテクチャと仕様

この設計は、AWS上にGophishをデプロイするための、セキュリティと自動化を考慮した構成です。

#### 1. 全体アーキテクチャ概要

```
(インターネット)
      |
      |---------------------------------------------------|
      | (Route 53)                                        |
      | gophish.ponponboo.com -> A -> EC2 Public IP         |
      | phish.ponponboo.com   -> A -> EC2 Public IP         |
      | (SPF, DKIM, DMARC レコード for ponponboo.com)       |
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
                        |  - Docker, Docker Compose, Certbot, EFS Utils, CloudWatch Agent
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

#### 2. 主要技術スタック

*   **インフラストラクチャ・アズ・コード (IaC):** Terraform
*   **コンテナ化:** Docker, Docker Compose
*   **クラウドプロバイダー:** Amazon Web Services (AWS)
*   **OS:** Amazon Linux 2
*   **メール送信:** Amazon SES
*   **DNS管理:** AWS Route 53
*   **SSL/TLS:** Let's Encrypt (Certbot)
*   **アクセス管理:** AWS Systems Manager Session Manager

#### 3. AWSリソースの詳細

Terraformによって以下のAWSリソースがプロビジョニングされます。

*   **IaC Core:**
    *   **S3 Backend:** Terraform Stateファイルの保存。
    *   **DynamoDB Table:** Terraform Stateロックによる同時実行制御。
*   **Networking:**
    *   **VPC:** 隔離されたネットワーク環境。
    *   **Public Subnet:** EC2インスタンスを配置。
    *   **Internet Gateway:** VPCとインターネット間の通信。
    *   **Route Table:** サブネットからのルーティング設定。
    *   **VPC Endpoints:** Systems Manager (SSM, SSMMessages, EC2Messages) へのプライベート接続。
*   **Compute:**
    *   **EC2 Instance:** Gophishアプリケーションをホスト。
        *   `user_data` スクリプトにより、Docker, Docker Compose, `amazon-efs-utils`, `certbot`, CloudWatch Agent を自動インストール。
    *   **IAM Role & Instance Profile:** EC2インスタンスにアタッチされ、以下の権限を付与。
        *   `AmazonSSMManagedInstanceCore`: Session Managerによるアクセスを許可。
        *   `secretsmanager:GetSecretValue`: Secrets ManagerからSMTP認証情報を取得。
        *   `cloudwatch:PutLogEvents`, `cloudwatch:CreateLogStream`, `cloudwatch:CreateLogGroup`: CloudWatch Logsへのログ送信。
        *   `s3:PutObject`: Session ManagerログのS3バケットへの書き込み。
*   **Storage:**
    *   **EFS File System & Mount Target:** Gophishのデータベース (`gophish.db`)、設定ファイル (`config.json`)、Let's Encrypt証明書などの永続データを保存。
    *   **S3 Bucket:** Session Managerのターミナルログを保存。
*   **DNS & Email:**
    *   **Route 53 Hosted Zone:** ドメイン `ponponboo.com` のDNSレコードを管理。
    *   **Route 53 Records:**
        *   Aレコード: `gophish.ponponboo.com` (管理画面), `phish.ponponboo.com` (フィッシングサイト) をEC2インスタンスのパブリックIPにマッピング。
        *   TXTレコード: SPF (`v=spf1 include:amazonses.com ~all`), DMARCポリシー。
        *   CNAMEレコード: DKIM認証用（Amazon SESが提供）。
    *   **SES Domain Identity:** ドメイン `ponponboo.com` の所有権をSESで検証。
    *   **SES DKIM:** ドメインのDKIM設定をSESで有効化。
*   **Security:**
    *   **Security Groups:**
        *   **Gophish Admin SG:** 特定のIPアドレスからのHTTPS (3333/tcp) アクセスを許可。
        *   **Gophish Phish SG:** 全てのIPアドレスからのHTTP (80/tcp) および HTTPS (443/tcp) アクセスを許可。
    *   **Secrets Manager Secret:** SESのSMTP認証情報（ユーザー名、パスワード）を安全に保管。

#### 4. セキュリティとロギング

*   **EC2アクセス:** SSHポートをインターネットに公開せず、AWS Systems Manager Session Manager を利用して安全にアクセス。
*   **セッションログ:** Session Managerのターミナルログは、Amazon S3とAmazon CloudWatch Logsに自動的に保存され、監査証跡として利用可能。
*   **SSL/TLS:** Gophish管理画面およびフィッシングサイトはLet's EncryptによるHTTPSで保護。
*   **メール認証:** Amazon SESと連携し、SPF, DKIM, DMARCを設定することで、メールの信頼性と到達率を向上。

#### 5. 構築・運用フローの概要

1.  **Terraform準備:** S3バックエンドとDynamoDBテーブルの手動作成、`terraform.tfvars` でのIPアドレス設定。
2.  **Terraform実行:** `terraform init`, `terraform plan`, `terraform apply` でAWSリソースをプロビジョニング。
3.  **DNS設定:** ドメインレジストラでRoute 53のネームサーバーに変更。
4.  **初回EC2設定:** Session ManagerでEC2に接続し、EFSマウント、`docker-compose.yml` と `config.json` の作成、Let's Encrypt証明書の取得、Gophish起動、初期パスワード確認。
5.  **自動更新設定:** `certbot renew` をcronジョブに登録。
6.  **AWSサービス最終設定:**
    *   **SESサンドボックス解除申請:** AWSサポートへ申請。
    *   **SMTP認証情報設定:** SESで作成した認証情報をSecrets Managerに保存。
    *   **Session Managerログ記録有効化:** Systems Managerコンソールで設定。

---

このまとめで、全体のアーキテクチャと仕様が明確になったでしょうか。