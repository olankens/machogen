# <samp>OVERVIEW</samp>

MacOS automatic setup for developers.

<img src="assets/img1.png" width="49.25%"/><img src="assets/img0.png" width="1.5%"/><img src="assets/img2.png" width="49.25%"/>

# <samp>GUIDANCE</samp>

### <samp>LAUNCH SCRIPT</samp>

Blindly executing this is strongly discouraged.

```shell
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/olankens/machogen/HEAD/src/machogen.sh)"
```

### <samp>IMPORT FUNCTIONS</samp>

Invoke specific functions only.

```shell
# Source machogen
source <"$(curl -fsSL https://raw.githubusercontent.com/olankens/machogen/HEAD/src/machogen.sh)"

# Update devtools
update_android_devtools
update_angular_devtools
```
