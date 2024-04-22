#!/bin/sh

set -e

dir=$(cd "$(dirname "$0")" && pwd)
cd "$dir/.."

die () { echo "$*" >&2; exit 1; }

# For the given XML file on disk ($1), gets the value of the
# specified XPath expression of the form "//$2/$3/$4/...".
xpath() {
  local xmlFile="$1"
  shift
  local expression="$@"
  local xpath="/"
  while [ $# -gt 0 ]
  do
    # NB: Ignore namespace issues; see: http://stackoverflow.com/a/8266075
    xpath="$xpath/*[local-name()='$1']"
    shift
  done
  local value=$(xmllint --xpath "$xpath/text()" "$xmlFile" 2> /dev/null)
  #debug "xpath $xmlFile $expression -> $value"
  echo "$value"
}

hasDep() {
  result=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='dependencies']/*[local-name()='dependency']/*[contains(.,'$2')]/text()" "$1" 2>/dev/null)
  if [ "$result" ]
  then
    echo YES
  fi
}

analyze() {
  slug=$1
  pom=$2
  fallbackLink=$(echo "https://github.com/${pom%.pom}" | tr '_' '/')
  #name=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='name']/text()" "$1")
  name=$(xpath "$1" project name)
  test "$name" || name="[UNKNOWN]"
  description=$(xpath "$1" project description)
  url=$(xpath "$1" project url)
  test "$url" || url="$fallbackLink"
  mailingListName=$(xpath "$1" project mailingLists mailingList name)
  mailingListArchive=$(xpath "$1" project mailingLists mailingList archive)
  test "$mailingListArchive" || mailingListArchive="$fallbackLink"
  scmUrl=$(xpath "$1" project scm url)
  test "$scmUrl" || scmUrl="$fallbackLink"
  imglib2=$(hasDep "$1" imglib2)
  bdv=$(hasDep "$1" bigdataviewer)
  imagej=$(hasDep "$1" net.imagej)
  fiji=$(hasDep "$1" sc.fiji)
  scijava=$(hasDep "$1" org.scijava)
  psj=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='parent']/*[contains(.,'pom-scijava')]/text()" "$1" 2>/dev/null)
  cats=
  test "$imagej" && cats="$cats, ImageJ"
  test "$fiji" && cats="$cats, Fiji"
  test "$bdv" && cats="$cats, BigDataViewer"
  test "$imglib2" && cats="$cats, ImgLib2"
  test "$scijava" -o "$psj" && cats="$cats, SciJava"
  cats=${cats#,}

  cat << DOC
---
title: "$name"
categories: [$cats ]
execute:
  echo: false
about:
  id: Aheading
  template: jolla
  image-shape: rounded
  image-width: 15em
  links:
    - text: Contact
      icon: envelope
      href: $mailingListArchive
    - text: Documentation
      icon: archive
      href: $url
    - text: GitHub
      icon: github
      href: $scmUrl

---

::: {.alignleft}

$description

:::
DOC
}

process() {
  slug=$1
  echo "Processing $slug"
  pom="$(echo "$slug" | tr '/' '_').pom"
  test -f "$pom" || {
    echo "--> Downloading pom.xml from GitHub..."
    curl -fsL https://github.com/$slug/raw/main/pom.xml > "$pom" ||
    curl -fsL https://github.com/$slug/raw/master/pom.xml > "$pom" ||
    die "pom.xml for $slug not found"
  } > "$pom"

  proj_name="${pom%.pom}"
  mkdir -p "ecosystem/$proj_name"
  analyze "$pom" > "ecosystem/$proj_name/index.qmd"
}

# -- Main --

for arg in $@
do
  process "$arg"
done
