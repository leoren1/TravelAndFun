$adb = "C:\Users\Asus_Pc\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$dev = "emulator-5554"
$out = "C:\Users\Asus_Pc\Desktop\TravelAndFun\screenshots"

function Shot($name) {
    & $adb -s $dev shell screencap -p /sdcard/shot.png
    & $adb -s $dev pull /sdcard/shot.png "$out\$name.png"
    Write-Output "Captured $name"
}

function Tap($x, $y) {
    & $adb -s $dev shell input tap $x $y
    Start-Sleep -Milliseconds 1200
}

function Swipe($x1, $y1, $x2, $y2) {
    & $adb -s $dev shell input swipe $x1 $y1 $x2 $y2 300
    Start-Sleep -Milliseconds 800
}

function Key($k) {
    & $adb -s $dev shell input keyevent $k
    Start-Sleep -Milliseconds 600
}

# Make sure we're on the app
& $adb -s $dev shell am start -n com.exploreindex.explore_index/.MainActivity
Start-Sleep -Seconds 3

# S1 - Dashboard (Home tab)
Shot "s1_dashboard"

# S2 - World Map (tap map tab, index 1)
Tap 640 1900
Start-Sleep -Seconds 2
Shot "s2_world_map"

# S3 - Country Detail (tap first country row - Turkey)
# Scroll down a bit to see countries list
Swipe 1280 1400 1280 900
Start-Sleep -Milliseconds 800
# Tap first country row
Tap 1280 700
Start-Sleep -Seconds 1
Shot "s3_country_detail"

# S4 - City Dashboard (tap first city - Istanbul)
Tap 1280 500
Start-Sleep -Seconds 1
Shot "s4_city_dashboard"

# S5 - Category Detail (tap first category tile)
Swipe 1280 1400 1280 900
Start-Sleep -Milliseconds 600
Tap 1280 700
Start-Sleep -Seconds 1
Shot "s5_category_detail"

# Go back to city dashboard
Key 4
Start-Sleep -Milliseconds 800

# S6 - Verify Visit (tap a place in category detail to visit)
# Actually navigate to a place and tap verify
# First go back to category detail
Tap 1280 700
Start-Sleep -Seconds 1
# Tap first place
Tap 1280 500
Start-Sleep -Seconds 1
Shot "s6_place_detail"

# Go back to city dashboard
Key 4
Start-Sleep -Milliseconds 500
Key 4
Start-Sleep -Milliseconds 500

# S7 - Events (tap Events shortcut card)
Swipe 1280 900 1280 600
Start-Sleep -Milliseconds 600
# Events card should be visible
Tap 1280 600
Start-Sleep -Seconds 1
Shot "s7_events"

# Go back
Key 4
Start-Sleep -Milliseconds 600

# S8 - Worth It Again (tap worth visiting card)
Swipe 1280 1400 1280 800
Start-Sleep -Milliseconds 600
Tap 1280 500
Start-Sleep -Seconds 1
Shot "s8_worth_it_again"

# Go back to city dashboard then back to map
Key 4
Start-Sleep -Milliseconds 600
Key 4
Start-Sleep -Milliseconds 600
Key 4
Start-Sleep -Milliseconds 600

# Go to Profile tab
Tap 1920 1900
Start-Sleep -Seconds 1
Shot "s9_profile"

# S10 - Discovery DNA (scroll down and tap DNA button)
Swipe 1280 1400 1280 700
Start-Sleep -Milliseconds 600
Swipe 1280 1400 1280 700
Start-Sleep -Milliseconds 600
Swipe 1280 1400 1280 700
Start-Sleep -Milliseconds 600
Tap 1280 854
Start-Sleep -Seconds 1
Shot "s10_discovery_dna"

Write-Output "All screenshots done!"
