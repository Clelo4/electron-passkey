{
  "targets": [
    {
      "target_name": "passkey",
      "sources": [],
      "include_dirs": [
        "src/lib",
        "<!(node -p \"require('node-addon-api').targets\"):node_addon_api"
      ],
      "dependencies": [
        "<!(node -p \"require('node-addon-api').targets\"):node_addon_api"
      ],
      "conditions": [
        ["OS=='mac'", {
          "sources": [
            "src/lib/passkey.mm"
          ],
          "link_settings": {
            "libraries": [
              "-lpthread",
              "-framework AppKit",
              "-framework ApplicationServices"
            ],
            "ldflags": ["-ObjC"]
          },
          "cflags+": [
            "-std=c++14",
            "-fvisibility=hidden"
          ],
          "xcode_settings": {
            "GCC_SYMBOLS_PRIVATE_EXTERN": "YES",
            "OTHER_CFLAGS": [
              "-fobjc-arc",
              "-fexceptions"
            ],
            "OTHER_CPLUSPLUSFLAGS": [
              "-std=c++14",
              "-ObjC++",
              "-fvisibility=hidden"
            ]
          }
        }],
        ["OS=='linux'", {
          "defines": [
            "_GNU_SOURCE"
          ],
          "link_settings": {
            "libraries": [
              "-lxcb", "-lpthread"
            ]
          }
        }]
      ],
      "cflags": [
        "-pedantic",
        "-Wall",
        "-pthread",
        "-fexceptions"
      ],
      "cflags+": [
        "-std=c++14",
        "-fvisibility=hidden"
      ],
      "cflags_cc": [
        "-std=c++14",
        "-fexceptions",
        "-fvisibility=hidden"
      ]
    }
  ]
}