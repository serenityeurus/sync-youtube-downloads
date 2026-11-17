# sync-youtube-downloads

Copies channel lines (`URL # name`, the format written by
export-youtube-subscriptions) from one file to the end of another. Lines whose URL the
destination already has are skipped. You can pass a profile name to insert a
yt-dlp option string between the URL and the comment.

```sh
cp sync-youtube-downloads.example.env sync-youtube-downloads.env
./sync-youtube-downloads ~/notes/pages/musicians.md channels.txt music-videos
# https://www.youtube.com/channel/UC... | --no-match-filters --match-filter ... # ODESZA

./sync-youtube-downloads ~/notes/pages/youtubers.md channels.txt   # no profile: URL # name
./sync-youtube-downloads --dry-run SRC DEST music-videos           # preview
```

Profiles live in the env file as `PROFILE_<NAME>=<string>` (`music-videos` maps to
`PROFILE_MUSIC_VIDEOS`). The value is taken literally. See `--help` for
the env file lookup order, matching rules and exit codes. Run the tests with `make ci`.
