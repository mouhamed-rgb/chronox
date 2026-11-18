from pathlib import Path
import re

app = Path('android/app')
manifest = app / 'src/main/AndroidManifest.xml'
if not manifest.exists():
    raise SystemExit(f'Missing Android manifest: {manifest}')

text = manifest.read_text(encoding='utf-8')
permissions = [
    'POST_NOTIFICATIONS', 'VIBRATE', 'WAKE_LOCK', 'RECEIVE_BOOT_COMPLETED',
    'SCHEDULE_EXACT_ALARM', 'USE_EXACT_ALARM', 'USE_FULL_SCREEN_INTENT',
]
for permission in permissions:
    marker = f'android.permission.{permission}'
    if marker not in text:
        text = text.replace(
            '<application',
            f'    <uses-permission android:name="{marker}" />\n    <application',
            1,
        )

# Only the launcher activity is configured to display over the lock screen.
if 'android:showWhenLocked' not in text:
    text = re.sub(
        r'<activity(?=[\s>])',
        '<activity\n            android:showWhenLocked="true"\n            android:turnScreenOn="true"',
        text,
        count=1,
    )

receivers = '''
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
'''
if 'ScheduledNotificationReceiver' not in text:
    text = text.replace('</application>', receivers + '\n    </application>', 1)
text = re.sub(r'android:label="[^"]*"', 'android:label="نبض"', text, count=1)
manifest.write_text(text, encoding='utf-8')

# Enable core-library desugaring in either Groovy or Kotlin Gradle DSL.
gradle_files = [app / 'build.gradle.kts', app / 'build.gradle']
gradle = next((p for p in gradle_files if p.exists()), None)
if gradle is None:
    raise SystemExit('No app/build.gradle(.kts) file was generated')
g = gradle.read_text(encoding='utf-8')
if 'coreLibraryDesugaringEnabled' not in g and 'isCoreLibraryDesugaringEnabled' not in g:
    if 'compileOptions {' in g:
        if gradle.suffix == '.kts':
            g = g.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
        else:
            g = g.replace('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true', 1)
    elif 'android {' in g:
        line = '        isCoreLibraryDesugaringEnabled = true' if gradle.suffix == '.kts' else '        coreLibraryDesugaringEnabled true'
        g = g.replace('android {', 'android {\n    compileOptions {\n' + line + '\n    }', 1)
    else:
        raise SystemExit('Could not locate android { } block in app Gradle file')

if 'desugar_jdk_libs' not in g:
    dependency = ('coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
                  if gradle.suffix == '.kts'
                  else "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'")
    if 'dependencies {' in g:
        g = g.replace('dependencies {', 'dependencies {\n    ' + dependency, 1)
    else:
        g += '\n\ndependencies {\n    ' + dependency + '\n}\n'
gradle.write_text(g, encoding='utf-8')
print('Android manifest and desugaring configuration patched successfully')
