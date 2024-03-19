# 引数の数を絞る
if [ $# -eq 1 ]; then
    git switch -c new_article/$1
    npx zenn new:article --slug $1
else
    echo "Argument not found. You must spacify the slug of the article."
fi