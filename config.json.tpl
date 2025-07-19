{
	"admin_server": {
		"listen_url": "0.0.0.0:3333",
		"use_tls": true,
		"cert_path": "/efs/gophish_admin.crt",
		"key_path": "/efs/gophish_admin.key",
		"trusted_origins": []
	},
	"phish_server": {
		"listen_url": "0.0.0.0:80",
		"use_tls": true,
		"cert_path": "/efs/phish.crt",
		"key_path": "/efs/phish.key"
	},
	"db_name": "sqlite3",
	"db_path": "/efs/gophish.db",
	"migrations_prefix": "db/db_",
	"contact_address": "",
	"logging": {
		"filename": "",
		"level": ""
	}
}