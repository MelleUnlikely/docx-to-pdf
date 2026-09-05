# Custom Gotenberg image that forces the system default paper size to Legal
# (8.5in x 14in), matching the CMR template's page setup.
#
# WHY THIS IS NEEDED
# -------------------
# Gotenberg's LibreOffice conversion route has no API parameter to control
# output page size (verified against the official docs) — it's expected to
# come from the document itself. Our document unambiguously specifies Legal
# size (confirmed: exactly one <w:sectPr>, one <w:pgSz w:w="12240"
# w:h="20160"/>, no conflicting definitions anywhere). Despite that,
# Gotenberg's container is converting it to A4.
#
# Gotenberg's base image is Debian, and Debian has a standard, well-defined
# mechanism for "what's the system default paper size" independent of any
# one application: the `libpaper` package, controlled by /etc/papersize and
# the PAPERSIZE environment variable. LibreOffice (a properly-packaged
# Debian application) consults this for print/export fallback behavior. A
# minimal container with no /etc/papersize configured, or one defaulting to
# "a4", is a well-known source of exactly this kind of silent page-size
# override — this is the most targeted, Debian-idiomatic fix available,
# though I can't verify it against your exact deployment from here, so
# please test after deploying.
#
# DEPLOY ON RENDER
# -----------------
# Render can build directly from a Dockerfile in a Git repo:
#   1. Push this file (named exactly "Dockerfile") to a new or existing
#      GitHub repo.
#   2. In Render: New -> Web Service -> connect that repo.
#      Render will auto-detect the Dockerfile and build from it (instead of
#      picking "Deploy an existing image" like before).
#   3. Set the port to 3000 (same as before), Free instance type, deploy.
#   4. Everything else (GOTENBERG_URL secret, the Edge Function, the Flutter
#      code) stays exactly the same — only the image being built changes.

FROM gotenberg/gotenberg:8

USER root

RUN \
  apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    libpaper-tools && \
  # Set the system-wide default paper size to Legal (8.5in x 14in).
  echo "legal" > /etc/papersize && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Belt-and-suspenders: also set it as an environment variable, since some
# tools check PAPERSIZE directly rather than reading /etc/papersize, and set
# an explicit US locale so nothing falls back to a metric/A4-oriented
# default for anything locale-driven.
ENV PAPERSIZE=legal
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_PAPER=en_US.UTF-8

USER gotenberg
