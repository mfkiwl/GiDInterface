
proc Kratos::InstallAllPythonDependencies { } {
    package require gid_cross_platform

    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    set dir [lindex [Kratos::GetLaunchConfigurationFile] 0]
    set py [Kratos::GetPythonExeName]
    # Check if python is installed. minimum 3.5, best 3.9
    set python_version [pythonVersion $py]
    if { $python_version <= 0 || [GidUtils::TwoVersionsCmp $python_version "3.10.8"] <0 } {
        ::GidUtils::SetWarnLine "Installing python"
        if {$os eq "win"} {
            gid_cross_platform::run_as_administrator [file join $::Kratos::kratos_private(Path) exec install_python_and_dependencies.win.bat ] $dir
        } {
            gid_cross_platform::run_as_administrator [file join $::Kratos::kratos_private(Path) exec install_python_and_dependencies.unix.sh ]
        }
    }

    if {$os ne "win"} {
        ::GidUtils::SetWarnLine "Installing python dependencies"
        gid_cross_platform::run_as_administrator [file join $::Kratos::kratos_private(Path) exec install_python_and_dependencies.unix.sh ]
    }

    if {$os eq "win"} {set pip "pyw"} {set pip "python3"}
    set missing_packages [Kratos::GetMissingPipPackages]
    ::GidUtils::SetWarnLine "Installing pip packages $missing_packages"
    if {[llength $missing_packages] > 0} {
        exec $pip -m pip install --no-cache-dir --disable-pip-version-check {*}$missing_packages
    }
    exec $pip -m pip install --upgrade --no-cache-dir --disable-pip-version-check {*}$Kratos::pip_packages_required
    ::GidUtils::SetWarnLine "Packages updated"
}

proc Kratos::InstallAllPythonDependenciesGID { } {
    package require gid_cross_platform
    set python_path [Kratos::GetPythonPath]
    set missing_packages [Kratos::GetMissingPipPackages]
    if {[llength $missing_packages] > 0} {
        ::GidUtils::SetWarnLine "Installing pip packages $missing_packages"
        gid_cross_platform::run_as_administrator $python_path -m pip install --no-cache-dir --disable-pip-version-check {*}$missing_packages
    }
    gid_cross_platform::run_as_administrator $python_path -m pip install --upgrade --no-cache-dir --disable-pip-version-check {*}$Kratos::pip_packages_required
    
    ::GidUtils::SetWarnLine "Packages updated"
}

proc Kratos::InstallPip { } {
    W ""
}

proc Kratos::GetPythonExeName { } {

    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    if {$os eq "win"} {set py "python"} {set py "python3"}
    return $py
}

proc Kratos::GetDefaultPythonPath { } {
    set pat ""
    catch {
        set py [Kratos::GetPythonExeName]
        set pat [exec $py -c "import sys; print(sys.executable)"  2>@1]
    }
    return $pat
}

#the definitive value to be used
proc Kratos::GetPythonPath { } {
    set python_exe_path [Kratos::ManagePreferences GetValue python_path]   
    if { $python_exe_path == "" } {
        set python_exe_path [Kratos::GetGiDPythonPath]        
        if { $python_exe_path == "" } {
            set python_exe_path [Kratos::GetDefaultPythonPath]
        }
    }
    return $python_exe_path
}

proc Kratos::pythonVersion {{pythonExecutable "python"}} {
    # Tricky point: Python 2.7 writes version info to stderr!
    set ver 0
    catch {
        set info [exec $pythonExecutable --version 2>@1]
        if {[regexp {^Python ([\d.]+)$} $info --> version]} {
            set ver $version
        }
    }
    return $ver
}

proc Kratos::GetPipVersion { python_exe_path } {
    set ver 0
    catch {
        set info [exec $python_exe_path -m pip --version 2>@1]
        if {[regexp {^pip ([\d.]+)*} $info --> version]} {
            set ver $version
        }
    }
    return $ver
}


proc Kratos::GetMissingPipPackages { } {
    variable pip_packages_required
    set missing_packages [list ]

    #set py [Kratos::GetPythonExeName]
    set python_exe_path [Kratos::GetPythonPath]
    set pip_packages_installed [list ]
    set pip_packages_installed_raw [exec $python_exe_path -m pip list --format=freeze --disable-pip-version-check 2>@1]
    foreach package $pip_packages_installed_raw {
        lappend pip_packages_installed [lindex [split $package "=="] 0]
    }
    foreach required_package $pip_packages_required {
        set required_package_name [lindex [split $required_package "=="] 0]
        if {$required_package_name ni $pip_packages_installed} {lappend missing_packages $required_package}
    }
    return $missing_packages
}


proc Kratos::CheckDependencies { {show 1} } {
    set curr_mode [Kratos::GetLaunchMode]
    set ret 0

    if {[dict exists $curr_mode dependency_check]} {
        set deps [dict get $curr_mode dependency_check]
        set ret [$deps]
    }
    if {$show} {ShowErrorsAndActions $ret}
    return $ret
}

proc Kratos::ShowErrorsAndActions {errs} {
    if { [GidUtils::IsTkDisabled] } {
        return 0
    }
    switch $errs {
        "MISSING_PYTHON" {
            W "Python 3 could not be found on this system."
            W "Please install python 3.9 with pip, and add the PATH to Kratos preferences before run the case."
            W "https://www.python.org/downloads/release/python-3913/"
        }
        "MISSING_PIP" {
            W "Pip is not installed on your system. Please install it by running in a terminal:"
            #set py [Kratos::GetPythonExeName]
            set python_exe_path [Kratos::GetPythonPath]
            set install_pip_path [file join $::Kratos::kratos_private(Path) exec get-pip.py]
            W "$python_exe_path $install_pip_path"
        }
        "MISSING_PIP_PACKAGES" {
            W "Kratos package was not found on your system."
            #set py [Kratos::GetPythonExeName]
            set python_exe_path [Kratos::GetPythonPath]
            W "Run the following command on a terminal:"
            W "$python_exe_path -m pip install --upgrade --force-reinstall --no-cache-dir $Kratos::pip_packages_required"
        }
        "DOCKER_NOT_FOUND" {
            W "Could not start docker. Please check if the Docker service is enabled."
        }
        "EXE_NOT_FOUND" {

        }
    }
}

proc Kratos::GetGiDPythonPath { } {
    #set python_exe_path [file join [gid_filesystem::get_folder_standard scripts] tohil/python/python.bat]
    if { $::tcl_platform(pointerSize) == 8 } {
            set bits 64
    } else {
            set bits 32
    }
    set python_exe_path [file join [gid_filesystem::get_folder_standard scripts] tohil/python/bin/x${bits}/python.exe]
    if { ![file exists $python_exe_path] } {
        set python_exe_path ""
    }
    return $python_exe_path
}


proc Kratos::CheckDependenciesPipMode {} {
    set ret 0
    set python_exe_path [Kratos::GetPythonPath]
    set pip_version 0    
    #set py [Kratos::GetPythonExeName]
    set py_version [Kratos::pythonVersion $python_exe_path]
    if {$py_version <= 0} {
        set ret "MISSING_PYTHON"
    } else {
        set pip_version [Kratos::GetPipVersion $python_exe_path]
        if {$pip_version <= 0} {
            set ret "MISSING_PIP"
        } else {
            set missing_packages [Kratos::GetMissingPipPackages]
            if {[llength $missing_packages] > 0} {
                set ret "MISSING_PIP_PACKAGES"
            }
        }
    }
    return $ret
}
proc Kratos::CheckDependenciesLocalPipMode {} {
    return 0
}
proc Kratos::CheckDependenciesLocalMode {} {
    return 0
}
proc Kratos::CheckDependenciesDockerMode {} {
    set ret 0
    try {
        exec docker ps
    } on error {msg} {
        W $msg
        set ret "DOCKER_NOT_FOUND"
    }
    return $ret
}

proc Kratos::GetLaunchConfigurationFile { } {
    set new_dir [file join $::env(HOME) .kratos_multiphysics]
    set file [file join $new_dir launch_configuration.json]
    return [list $new_dir $file]
}

proc Kratos::LoadLaunchModes { {force 0} } {
    # Get location of launch config script
    lassign [Kratos::GetLaunchConfigurationFile] new_dir file

    # If it does not exist, copy it from exec
    if {[file exists $new_dir] == 0} {file mkdir $new_dir}
    if {[file exists $file] == 0 || $force} {
        ::GidUtils::SetWarnLine "Loading launch mode"
        set source [file join $::Kratos::kratos_private(Path) exec launch.json]
        file copy -force $source $file
    }

    # Load configurations
    Kratos::LoadConfigurationFile $file
}

proc Kratos::LoadConfigurationFile {config_file} {
    if {[file exists $config_file] == 0} { error "Configuration file not found: $config_file" }

    set dic [Kratos::ReadJsonDict $config_file]
    set ::Kratos::kratos_private(configurations) [dict get $dic configurations]
}

proc Kratos::SetDefaultLaunchMode { } {
    set curr_mode $Kratos::kratos_private(launch_configuration)
    set modes [list ]
    set first ""
    foreach mode $::Kratos::kratos_private(configurations) {
        set mode_name [dict get $mode name]
        lappend modes $mode_name
        if {$first eq ""} {set first $mode_name}
    }
    if {$curr_mode ni $modes} {set Kratos::kratos_private(launch_configuration) $first}
}

proc Kratos::ExecuteLaunchByMode {launch_mode} {
    set bat_file ""
    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    set mode [Kratos::GetLaunchMode $launch_mode]
    if {$mode ne ""} {
        set bat [dict get $mode script]
        set bat_file [file join exec $bat.$os.bat]
    }
    if {[dict get $mode name] eq "Docker"} {
        set docker_image [Kratos::ManagePreferences GetValue docker_image]
        set ::env(kratos_docker_image) $docker_image
    } else {
        set python_exe_path [Kratos::GetPythonPath]
        set ::env(kratos_python_exe) $python_exe_path
    }
    return $bat_file
}

proc Kratos::GetLaunchMode { {launch_mode "current"} } {
    set curr_mode ""
    if {$launch_mode eq "current"} {set launch_mode $Kratos::kratos_private(launch_configuration)}
    foreach mode $::Kratos::kratos_private(configurations) {
        set mode_name [dict get $mode name]
        if {$mode_name eq $launch_mode} {
            set curr_mode $mode
        }
    }
    return $curr_mode
}

proc Kratos::StopCalculation { } {
    if {[dict get [Kratos::GetLaunchMode] name] eq "Docker"} {
        exec docker stop [Kratos::GetModelName]
    }
    GiD_Process Mescape Utilities CancelProcess escape escape
}