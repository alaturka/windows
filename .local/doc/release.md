Release
=======

- [ ] Edit `CHANGELOG.md`

  ```sh
  git commit CHANGELOG.md -m "chore: changelog for upcoming release"
  ```

- [ ] Do updates if any

- [ ] Run tests

- [ ] Fix errors if any

- [ ] Release

  ```sh
  git commit -a -m "chore: release x.x.x"
  ```

- [ ] Merge into main branch

  ```sh
  git checkout master
  git merge dev
  git checkout dev
  ```

- [ ] Tag

  ```sh
  git tag -a x.x.x -m "Releasing version x.x.x"
  ```

- [ ] Publish

  ```sh
  git push
  git push --tags
  ```
