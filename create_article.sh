# 引数の数を絞る
if [ $# -eq 1 ]; then
    # 他の記事の branch で作業中に実行しても main から switch できるように
    git switch main
    git switch -c feature/$1
    npx zenn new:article --slug $1
else
    echo "Argument not found. You must spacify the slug of the article."
fi