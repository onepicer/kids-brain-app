# HEARTBEAT.md

## Flutter APK Build Check
- **Build started**: 11:32
- **Log file**: `/tmp/flutter_build.log`
- **Status**: Building (Flutter running)
- **Check**: Every heartbeat, run `tail -5 /tmp/flutter_build.log` and check for EXIT_CODE
- If EXIT_CODE=0: copy APK from `build/app/outputs/flutter-apk/app-release.apk` to `/mnt/d/个人文件/Desktop/` and notify 主人
- If failed: check error, notify 主人
