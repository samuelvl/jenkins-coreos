{
  "ignition": {
    "config": {
      "replace": {
        "source": null,
        "verification": {}
      }
    },
    "security": {
      "tls": {}
    },
    "timeouts": {},
    "version": "3.0.0"
  },
  "passwd": {
    "users": [
      {
        "name": "maintuser",
        "groups": [
          "sudo"
        ],
        "sshAuthorizedKeys": [
          "${ssh_allowed_pubkey}"
        ]
      }
    ]
  },
  "storage": {
    "files": [
      {
        "group": {
          "name": "root"
        },
        "overwrite": true,
        "path": "/etc/hostname",
        "user": {
          "name": "root"
        },
        "contents": {
          "source": "data:text/plain;charset=utf-8;base64,${hostname_b64}",
          "verification": {}
        },
        "mode": 420
      }
    ]
  },
  "systemd": {}
}
