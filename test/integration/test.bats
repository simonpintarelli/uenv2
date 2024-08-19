function setup() {
    bats_install_path=$(realpath ./install)
    export BATS_LIB_PATH=$bats_install_path/bats-helpers

    bats_load_library bats-support
    bats_load_library bats-assert
    load ./common

    export REPOS=$(realpath ../scratch/repos)
}

function teardown() {
    :
}

@test "noargs" {
    # nothing is done if no --uenv is present and UENV_MOUNT_LIST is empty
    unset UENV_MOUNT_LIST
    run_srun_unchecked  bash -c 'findmnt -r | grep /user-environment'
    refute_output --partial '/user-environment'
}

@test "mount uenv" {
    unset UENV_MOUNT_LIST
    export UENV_REPO_PATH=$REPOS/apptool

    # if no mount point is provided the default provided by the uenv's meta
    # data should be used.

    # app has default mount /user-environment
    run_srun_unchecked  --uenv=app/42.0 bash -c 'findmnt -r | grep /user-environment'
    assert_output --partial '/user-environment'

    # tool has default mount /user-tools
    run_srun_unchecked  --uenv=tool bash -c 'findmnt -r | grep /user-tools'
    assert_output --partial '/user-tools'

    # if the view is mounted, the app should be visible
    run_srun_unchecked  --uenv=app/42.0 --view=app app
    assert_output --partial 'hello app'

    # if the view is mounted, the app should be visible
    run_srun_unchecked  --uenv=tool --view=tool tool
    assert_output --partial 'hello tool'

    # check that the correct uenv with name app is chosen
    run_srun_unchecked  --uenv=app/43.0 --view=app app --version
    assert_output --partial '43.0'
    run_srun_unchecked  --uenv=app/42.0 --view=app app --version
    assert_output --partial '42.0'

    # an error should be generated if an ambiguous uenv is requested
    run_srun_unchecked  --uenv=app --view=app app --version
    assert_output --partial "error: more than one uenv matches the uenv description 'app'"

    unset UENV_REPO_PATH
    run_srun_unchecked  --uenv=app/43.0 --repo=$REPOS/apptool --view=app app
    assert_output --partial 'hello app'
    run_srun_unchecked  --uenv=app/42.0:v1@arapiles%zen3,tool --repo=$REPOS/apptool --view=app,tool tool
    assert_output --partial 'hello tool'
}

@test "views" {
    unset UENV_MOUNT_LIST
    export UENV_REPO_PATH=$REPOS/apptool

    # if the view is mounted, the app should be visible
    run_srun_unchecked  --uenv=app/42.0 --view=app app
    assert_output --partial 'hello app'

    # if the view is mounted, the app should be visible
    run_srun_unchecked  --uenv=tool --view=tool tool
    assert_output --partial 'hello tool'

    # check multiple views + uenv
    run_srun_unchecked  --uenv=app/42.0,tool --view=app,tool bash -c "tool; app"
    assert_output --partial 'hello tool'
    assert_output --partial 'hello app'
    run_srun_unchecked  --uenv=app/42.0,tool --view=app:app,tool:tool bash -c "tool; app"
    assert_output --partial 'hello tool'
    assert_output --partial 'hello app'

    # check that invalid view names are caught
    run_srun_unchecked  --uenv=tool --view=tools true
    assert_output --partial "the requested view 'tools' is not provided"
    run_srun_unchecked  --uenv=app/42.0,tool --view=app:app,tool:tools true
    assert_output --partial "the requested view 'tools' is not provided"
    run_srun_unchecked  --uenv=app/42.0,tool --view=app:app,wombat:tool true
    assert_output --partial "the requested view 'tools' is not provided"
}

# check for invalid arguments passed to --uenv
@test "faulty --uenv argument" {
    export UENV_REPO_PATH=$REPOS/apptool

    run_srun_unchecked --uenv=a:b:c true
    assert_output --partial 'expected a path'

    run_srun_unchecked --uenv=a:/wombat true
    assert_output --partial "invalid uenv description: found unexpected '/'"

    run_srun_unchecked --uenv=a? true
    assert_output --partial "invalid uenv description: unexpected symbol '?'"

    run_srun_unchecked --uenv=app: true
    assert_output --partial 'invalid uenv description:'

    run_srun_unchecked --uenv=app/42.0:v1@arapiles%zen3+ ls /user-environment
    assert_output --partial "invalid uenv description: unexpected symbol '+'"
}
