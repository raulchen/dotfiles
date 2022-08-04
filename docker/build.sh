set -e
git_user=$(git config user.name)
git_email=$(git config user.email)
docker build --build-arg git_user="$git_user" --build-arg git_email="git_email" \
    --platform linux/x86_64 -t my/dev $@ .
