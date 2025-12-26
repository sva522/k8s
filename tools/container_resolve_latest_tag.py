#!/usr/bin/env python3
from argparse import ArgumentParser
import requests
from sys import stderr, exit

DEFAULT_REGISTRY = 'https://registry.hub.docker.com'
DEFAULT_REPO_PREFIX = 'library'

def get_tags(registry, image):
    tags = []
    url = f'{registry}/v2/repositories/{image}/tags?page_size=100'
    while url:
        try:
            response = requests.get(url)
            response.raise_for_status()
            data = response.json()
            tags.extend(data.get('results', []))
            url = data.get('next')
        except Exception as error:
            print(f'Error while fetching tags: {error}', file=stderr)
            print('error_not_latest_found')
            exit(1)
    return tags

def find_latest_digest(tags):
    for tag in tags:
        if tag.get('name') == 'latest':
            images = tag.get('images', [])
            if images:
                return images[0].get('digest')
    return None

def find_version_by_digest(tags, digest):
    for tag in tags:
        if tag.get('name') != 'latest':
            images = tag.get('images', [])
            for image in images:
                if image.get('digest') == digest:
                    return tag.get('name')
    return None

def main():
    parser = ArgumentParser(description='Find the version tag matching the "latest" digest')
    parser.add_argument('image', help='Docker image name (e.g. alpine)')
    parser.add_argument('--registry', default=DEFAULT_REGISTRY, help='Registry URL (default: Docker Hub)')
    parser.add_argument('--prefix', default=DEFAULT_REPO_PREFIX, help='Repository prefix (default: library)')
    args = parser.parse_args()

    full_image = f'{args.prefix}/{args.image}' if args.prefix else args.image
    tags = get_tags(args.registry, full_image)

    latest_digest = find_latest_digest(tags)
    if not latest_digest:
        print('Could not find digest for "latest" tag', file=stderr)
        print('error_not_latest_found')
        exit(1)

    version_tag = find_version_by_digest(tags, latest_digest)
    if version_tag:
        print(version_tag)
    else:
        print('No version tag matches the "latest" digest', file=stderr)
        print('error_not_latest_found')
        exit(1)

if __name__ == '__main__':
    main()
