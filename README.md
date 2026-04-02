> **Note:** To access all shared projects, get information about environment setup, and view other guides, please visit [Explore-In-HMOS-Wearable Index](https://github.com/Explore-In-HMOS-Wearable/hmos-index).

# Throw the Lines

Throw the Lines is a demo game app that challenges users to carefully place balls on a rotating circle without hitting existing ones. It includes classic and advanced game modes and guides you step‑by‑step through levels. 

# Preview
<div>
  <img src="screenshots/p0.png" width="24%">
  <img src="screenshots/p2.png" width="24%">
  <img src="screenshots/p1.png" width="24%">
  <img src="screenshots/p3.png" width="24%">
</div>

# Use Cases

Throw the Lines lets users:

* Play classic mode with increasing difficulty and advanced mode with special challenges.
* Follow step-by-step level progression.

# Tech Stack

Languages: ArkTS
Frameworks: HarmonyOS SDK 5.1.0(18)
Tools: DevEco Studio Vers 5.1.0.820
Libraries: `@kit.ArkUI`

# Directory Structure

```
  entry/src/main/ets/
  |---entryability
  |   |---EntryAbility.ets
  |---entrybackupability
  |   |---EntryBackupAbility.ets
  |---model
  |   |---LevelConfig.ets
  |   |---ScreenState.ets
  |---pages
  |   |---Index.ets                       
  |---service
  |   |---DrawService.ets                 
  |   |---LevelService.ets                 
  |---util
  |   |---ConstantUI.ets                 
  |---viewmodel
  |   |---GameViewModel.ets                 

```

# Constraints and Restrictions
## Supported Devices
Huawei Watch 5

# LICENSE

Throw the Lines is distributed under the terms of the MIT License.  
See the [LICENSE](/LICENSE) for more information.