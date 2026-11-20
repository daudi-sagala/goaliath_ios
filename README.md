# Goaliath iOS V4 media updates

Merge the 15 Swift files into your EXISTING iOS Xcode project at the same relative paths.
This patch builds on the previous V3 questionnaire-submission changes. It does not include any compiled iOS app.

The media URL arrays (`image_urls`, `video_urls`, `gif_urls`) were added as optional Swift model properties to preserve old Codable snapshots.
The Add to Timeline form accepts multiple hosted HTTPS links and can use existing PhotosPicker files with an explicitly configured public bucket for Everyone-visible posts and scheduled items only.
The Reply and Chat composers accept hosted HTTPS links, rather than silently uploading private content into a public bucket.
See backend `docs/MULTI_MEDIA_V4.md` for media endpoint setup and privacy cautions.
Run a full Xcode build on your Mac before deploying.
