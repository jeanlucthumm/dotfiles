Agents use a ./PR.md file as working memory and to align during PR implementation.

However, this file should not be part of the final PR.

If the user issued this command, then we are ready to finalize the PR.

First confirm that PR.md looks complete.
Then move the PR.md to ../context/prmd/<branch-name>.md.

Then check if there's a gh PR (use gh CLI), and confirm that the description
is good.
