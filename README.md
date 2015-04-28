# Shoots Deploy

##Deploying websites the sucky old ways
The amount of work it takes to deploy static websites these days just isn't as fast and simple as it should be. You either use FTP or SCP or some paid hosted service such as the excellent `Brace.io`.

I personally love hosting my static websites on Amazon S3 because it's ridiculously cheap and flexible. It's not slow and it allows for multiple regions.

##ShootsDeploy - The quick and simple way
This gem allows you to deploy static websites to your Amazon S3 by simply typing in command line in the root directory of your site.

```
gem install shoots_deploy
shoots
```

Bam! In 30 seconds your site is live and/or updated!

##Notes
You should add `shoots.yml` in your `.gitignore`!

Scenarios
  - Deployed before √
  - custom domain with r53 with root domain √
  - custom domain with r53 with no root domain √
  - custom domain with no r53 √
  - no custom domain √

Edge cases not accounted for
  - Bucket name taken

##To do:
1. Test `http://www.smashingmagazine.com/2014/04/08/how-to-build-a-ruby-gem-with-bundler-test-driven-development-travis-ci-and-coveralls-oh-my/`
2. Documentation `http://guides.rubygems.org/make-your-own-gem/#documenting-code`
3. Refactor
4. Rename to `ShootDeploy`?

##Contributing:
1. Git clone this repository
2. Make changes to code
3. gem build shoots_deploy.gemspec
4. gem install ./shoots_deploy-<version-number>.gem
