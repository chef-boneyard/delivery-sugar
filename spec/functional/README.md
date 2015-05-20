# Functional Testing README

This README documents the necessary setup for creating a bundled git repository
that can be used for functional testing.

## Creating a new Git Bundle

    $ mkdir functional_test_repo
    $ cd ./functional_test_repo
    $ git init .
    ...make changes...
    $ git bundle create ../functional_test_repo.bundle --all
    $ cd ../
    $ rm -rf functional_test_repo

## Updating an existing Git Bundle

    $ git clone functional_test_repo.bundle repo -b master
    ...make changes...
    $ git bundle create ../functional_test_repo.bundle --all
