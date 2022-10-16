Before you do a pull request, you should always **file an issue** and make sure the package maintainer agrees that it's a problem, and is happy with your basic proposal for fixing it. We don't want you to spend a bunch of time on something that we don't think is a good idea.

Additional requirements for pull requests:

-   Adhere to the [Developer Guidelines](https://ohdsi.github.io/MethodsLibrary/developerGuidelines.html) as well as the [OHDSI Code Style](https://ohdsi.github.io/MethodsLibrary/codeStyle.html).

-   If possible, add unit tests for new functionality you add.

-   Restrict your pull request to solving the issue at hand. Do not try to 'improve' parts of the code that are not related to the issue. If you feel other parts of the code need better organization, create a separate issue for that.

-   Make sure you pass R check without errors and warnings before submitting.

-   Always target the `develop` branch, and make sure you are up-to-date with the develop branch.
