



<!DOCTYPE html>
<html lang="en" class="">
  <head prefix="og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# object: http://ogp.me/ns/object# article: http://ogp.me/ns/article# profile: http://ogp.me/ns/profile#">
    <meta charset='utf-8'>
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta http-equiv="Content-Language" content="en">
    
    
    <title>OpenStudio-Beopt/measure.rb at PSD · NREL/OpenStudio-Beopt</title>
    <link rel="search" type="application/opensearchdescription+xml" href="/opensearch.xml" title="GitHub">
    <link rel="fluid-icon" href="https://github.com/fluidicon.png" title="GitHub">
    <link rel="apple-touch-icon" sizes="57x57" href="/apple-touch-icon-114.png">
    <link rel="apple-touch-icon" sizes="114x114" href="/apple-touch-icon-114.png">
    <link rel="apple-touch-icon" sizes="72x72" href="/apple-touch-icon-144.png">
    <link rel="apple-touch-icon" sizes="144x144" href="/apple-touch-icon-144.png">
    <meta property="fb:app_id" content="1401488693436528">

      <meta content="@github" name="twitter:site" /><meta content="summary" name="twitter:card" /><meta content="NREL/OpenStudio-Beopt" name="twitter:title" /><meta content="Contribute to OpenStudio-Beopt development by creating an account on GitHub." name="twitter:description" /><meta content="https://avatars1.githubusercontent.com/u/1906800?v=2&amp;s=400" name="twitter:image:src" />
<meta content="GitHub" property="og:site_name" /><meta content="object" property="og:type" /><meta content="https://avatars1.githubusercontent.com/u/1906800?v=2&amp;s=400" property="og:image" /><meta content="NREL/OpenStudio-Beopt" property="og:title" /><meta content="https://github.com/NREL/OpenStudio-Beopt" property="og:url" /><meta content="Contribute to OpenStudio-Beopt development by creating an account on GitHub." property="og:description" />

      <meta name="browser-stats-url" content="/_stats">
    <link rel="assets" href="https://assets-cdn.github.com/">
    <link rel="conduit-xhr" href="https://ghconduit.com:25035">
    <link rel="xhr-socket" href="/_sockets">

    <meta name="msapplication-TileImage" content="/windows-tile.png">
    <meta name="msapplication-TileColor" content="#ffffff">
    <meta name="selected-link" value="repo_source" data-pjax-transient>
      <meta name="google-analytics" content="UA-3769691-2">

    <meta content="collector.githubapp.com" name="octolytics-host" /><meta content="collector-cdn.github.com" name="octolytics-script-host" /><meta content="github" name="octolytics-app-id" /><meta content="C0AE2532:3F00:193F2E9:5411D9A7" name="octolytics-dimension-request_id" /><meta content="8376057" name="octolytics-actor-id" /><meta content="jmaguire1" name="octolytics-actor-login" /><meta content="0c6b8418465130aec4c06f2dc5d73b00df34d06364718e45960953c7d62c48c4" name="octolytics-actor-hash" />
    <meta content="Rails, view, blob#show" name="analytics-event" />

    
    
    <link rel="icon" type="image/x-icon" href="https://assets-cdn.github.com/favicon.ico">


    <meta content="authenticity_token" name="csrf-param" />
<meta content="rYg4fMEHW/KBvXh268Y2EWR9Ddx7Rp+tYrrxDWk8O6EXpw3iBSsLQX4Wejp+U3Iw/pgym+bvGnchFxpqcwLpGA==" name="csrf-token" />

    <link href="https://assets-cdn.github.com/assets/github-e98a2e283e3419aa85768affc5929842870bc5fc.css" media="all" rel="stylesheet" type="text/css" />
    <link href="https://assets-cdn.github.com/assets/github2-c63e67d784fa7ee064d9610f2d22cdf8d0d7f467.css" media="all" rel="stylesheet" type="text/css" />
    


    <meta http-equiv="x-pjax-version" content="37f365d9c8bc52a9b54820d2549e77db">

      
  <meta name="description" content="Contribute to OpenStudio-Beopt development by creating an account on GitHub.">
  <meta name="go-import" content="github.com/NREL/OpenStudio-Beopt git https://github.com/NREL/OpenStudio-Beopt.git">

  <meta content="1906800" name="octolytics-dimension-user_id" /><meta content="NREL" name="octolytics-dimension-user_login" /><meta content="23157648" name="octolytics-dimension-repository_id" /><meta content="NREL/OpenStudio-Beopt" name="octolytics-dimension-repository_nwo" /><meta content="false" name="octolytics-dimension-repository_public" /><meta content="false" name="octolytics-dimension-repository_is_fork" /><meta content="23157648" name="octolytics-dimension-repository_network_root_id" /><meta content="NREL/OpenStudio-Beopt" name="octolytics-dimension-repository_network_root_nwo" />
  <link href="https://github.com/NREL/OpenStudio-Beopt/commits/PSD.atom?token=8376057__eyJzY29wZSI6IkF0b206L05SRUwvT3BlblN0dWRpby1CZW9wdC9jb21taXRzL1BTRC5hdG9tIiwiZXhwaXJlcyI6Mjk4ODM4Mjc3OH0%3D--cf607347408c0cfedac182d68fe8ba580e6c09f7" rel="alternate" title="Recent Commits to OpenStudio-Beopt:PSD" type="application/atom+xml">

  </head>


  <body class="logged_in  env-production windows vis-private page-blob">
    <a href="#start-of-content" tabindex="1" class="accessibility-aid js-skip-to-content">Skip to content</a>
    <div class="wrapper">
      
      
      
      


      <div class="header header-logged-in true">
  <div class="container clearfix">

    <a class="header-logo-invertocat" href="https://github.com/" aria-label="Homepage" ga-data-click="Header, go to dashboard, icon:logo">
  <span class="mega-octicon octicon-mark-github"></span>
</a>


      <div class="site-search repo-scope js-site-search">
          <form accept-charset="UTF-8" action="/NREL/OpenStudio-Beopt/search" class="js-site-search-form" data-global-search-url="/search" data-repo-search-url="/NREL/OpenStudio-Beopt/search" method="get"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>
  <input type="text"
    class="js-site-search-field is-clearable"
    data-hotkey="s"
    name="q"
    placeholder="Search"
    data-global-scope-placeholder="Search GitHub"
    data-repo-scope-placeholder="Search"
    tabindex="1"
    autocapitalize="off">
  <div class="scope-badge">This repository</div>
</form>
      </div>
      <ul class="header-nav left">
        <li class="header-nav-item explore">
          <a class="header-nav-link" href="/explore" data-ga-click="Header, go to explore, text:explore">Explore</a>
        </li>
          <li class="header-nav-item">
            <a class="header-nav-link" href="https://gist.github.com" data-ga-click="Header, go to gist, text:gist">Gist</a>
          </li>
          <li class="header-nav-item">
            <a class="header-nav-link" href="/blog" data-ga-click="Header, go to blog, text:blog">Blog</a>
          </li>
        <li class="header-nav-item">
          <a class="header-nav-link" href="https://help.github.com" data-ga-click="Header, go to help, text:help">Help</a>
        </li>
      </ul>

    
<ul class="header-nav user-nav right" id="user-links">
  <li class="header-nav-item dropdown js-menu-container">
    <a class="header-nav-link name" href="/jmaguire1" data-ga-click="Header, go to profile, text:username">
      <img alt="jmaguire1" class="avatar" data-user="8376057" height="20" src="https://avatars2.githubusercontent.com/u/8376057?v=2&amp;s=40" width="20" />
      <span class="css-truncate">
        <span class="css-truncate-target">jmaguire1</span>
      </span>
    </a>
  </li>

  <li class="header-nav-item dropdown js-menu-container">
    <a class="header-nav-link js-menu-target tooltipped tooltipped-s" href="#" aria-label="Create new..." data-ga-click="Header, create new, icon:add">
      <span class="octicon octicon-plus"></span>
      <span class="dropdown-caret"></span>
    </a>

    <div class="dropdown-menu-content js-menu-content">
      
<ul class="dropdown-menu">
  <li>
    <a href="/new"><span class="octicon octicon-repo"></span> New repository</a>
  </li>
  <li>
    <a href="/organizations/new"><span class="octicon octicon-organization"></span> New organization</a>
  </li>


    <li class="dropdown-divider"></li>
    <li class="dropdown-header">
      <span title="NREL/OpenStudio-Beopt">This repository</span>
    </li>
      <li>
        <a href="/NREL/OpenStudio-Beopt/issues/new"><span class="octicon octicon-issue-opened"></span> New issue</a>
      </li>
</ul>

    </div>
  </li>

  <li class="header-nav-item">
        <a href="/notifications" aria-label="You have no unread notifications" class="header-nav-link notification-indicator tooltipped tooltipped-s" data-ga-click="Header, go to notifications, icon:read" data-hotkey="g n">
        <span class="mail-status all-read"></span>
        <span class="octicon octicon-inbox"></span>
</a>
  </li>

  <li class="header-nav-item">
    <a class="header-nav-link tooltipped tooltipped-s" href="/settings/profile" id="account_settings" aria-label="Settings" data-ga-click="Header, go to settings, icon:settings">
      <span class="octicon octicon-gear"></span>
    </a>
  </li>

  <li class="header-nav-item">
    <form accept-charset="UTF-8" action="/logout" class="logout-form" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="kimVGZbTQMWR237XrzEtGjzJr4+vVCy/aF5bKN66ZJJw1GDa0JTPeGLHdKpQg3RZ1pUFeYZBeOlznGowAsC/3g==" /></div>
      <button class="header-nav-link sign-out-button tooltipped tooltipped-s" aria-label="Sign out" data-ga-click="Header, sign out, icon:logout">
        <span class="octicon octicon-sign-out"></span>
      </button>
</form>  </li>

</ul>


    
  </div>
</div>

      

        


      <div id="start-of-content" class="accessibility-aid"></div>
          <div class="site" itemscope itemtype="http://schema.org/WebPage">
    <div id="js-flash-container">
      
    </div>
    <div class="pagehead repohead instapaper_ignore readability-menu">
      <div class="container">
        
<ul class="pagehead-actions">

    <li class="subscription">
      <form accept-charset="UTF-8" action="/notifications/subscribe" class="js-social-container" data-autosubmit="true" data-remote="true" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="rmxWmhAb1jZxFRT2dpVXNRBdeqa+kKq8LxTJhOF4N4YYC5sbLUfgMwgd7kJl/wwG72/c3c4hsQxL7+VQc5omjQ==" /></div>  <input id="repository_id" name="repository_id" type="hidden" value="23157648" />

    <div class="select-menu js-menu-container js-select-menu">
      <a class="social-count js-social-count" href="/NREL/OpenStudio-Beopt/watchers">
        32
      </a>
      <a href="/NREL/OpenStudio-Beopt/subscription"
        class="minibutton select-menu-button with-count js-menu-target" role="button" tabindex="0" aria-haspopup="true">
        <span class="js-select-button">
          <span class="octicon octicon-eye"></span>
          Unwatch
        </span>
      </a>

      <div class="select-menu-modal-holder">
        <div class="select-menu-modal subscription-menu-modal js-menu-content" aria-hidden="true">
          <div class="select-menu-header">
            <span class="select-menu-title">Notifications</span>
            <span class="octicon octicon-x js-menu-close" role="button" aria-label="Close"></span>
          </div> <!-- /.select-menu-header -->

          <div class="select-menu-list js-navigation-container" role="menu">

            <div class="select-menu-item js-navigation-item " role="menuitem" tabindex="0">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <div class="select-menu-item-text">
                <input id="do_included" name="do" type="radio" value="included" />
                <h4>Not watching</h4>
                <span class="description">Be notified when participating or @mentioned.</span>
                <span class="js-select-button-text hidden-select-button-text">
                  <span class="octicon octicon-eye"></span>
                  Watch
                </span>
              </div>
            </div> <!-- /.select-menu-item -->

            <div class="select-menu-item js-navigation-item selected" role="menuitem" tabindex="0">
              <span class="select-menu-item-icon octicon octicon octicon-check"></span>
              <div class="select-menu-item-text">
                <input checked="checked" id="do_subscribed" name="do" type="radio" value="subscribed" />
                <h4>Watching</h4>
                <span class="description">Be notified of all conversations.</span>
                <span class="js-select-button-text hidden-select-button-text">
                  <span class="octicon octicon-eye"></span>
                  Unwatch
                </span>
              </div>
            </div> <!-- /.select-menu-item -->

            <div class="select-menu-item js-navigation-item " role="menuitem" tabindex="0">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <div class="select-menu-item-text">
                <input id="do_ignore" name="do" type="radio" value="ignore" />
                <h4>Ignoring</h4>
                <span class="description">Never be notified.</span>
                <span class="js-select-button-text hidden-select-button-text">
                  <span class="octicon octicon-mute"></span>
                  Stop ignoring
                </span>
              </div>
            </div> <!-- /.select-menu-item -->

          </div> <!-- /.select-menu-list -->

        </div> <!-- /.select-menu-modal -->
      </div> <!-- /.select-menu-modal-holder -->
    </div> <!-- /.select-menu -->

</form>
    </li>

  <li>
    
  <div class="js-toggler-container js-social-container starring-container ">

    <form accept-charset="UTF-8" action="/NREL/OpenStudio-Beopt/unstar" class="js-toggler-form starred js-unstar-button" data-remote="true" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="3I3j3QV6u47nloMCUIXrMOMe6I45seyyD+7rHgyhSHVr7j6lE6wfOEDiP4MHaO5skna/Vi9yL9S664pn+LKlVA==" /></div>
      <button
        class="minibutton with-count js-toggler-target star-button"
        aria-label="Unstar this repository" title="Unstar NREL/OpenStudio-Beopt">
        <span class="octicon octicon-star"></span>
        Unstar
      </button>
        <a class="social-count js-social-count" href="/NREL/OpenStudio-Beopt/stargazers">
          0
        </a>
</form>
    <form accept-charset="UTF-8" action="/NREL/OpenStudio-Beopt/star" class="js-toggler-form unstarred js-star-button" data-remote="true" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="Wbc7AFyA+/VVOvxnhBI53koRVfqqBxN9XTN8UrT2BbVGE7wbORmdUKMhzVygo75+/mo5Y8t0i4RZdRrmgdclKw==" /></div>
      <button
        class="minibutton with-count js-toggler-target star-button"
        aria-label="Star this repository" title="Star NREL/OpenStudio-Beopt">
        <span class="octicon octicon-star"></span>
        Star
      </button>
        <a class="social-count js-social-count" href="/NREL/OpenStudio-Beopt/stargazers">
          0
        </a>
</form>  </div>

  </li>


        <li>
          <a href="/NREL/OpenStudio-Beopt/fork" class="minibutton with-count js-toggler-target fork-button tooltipped-n" title="Fork your own copy of NREL/OpenStudio-Beopt to your account" aria-label="Fork your own copy of NREL/OpenStudio-Beopt to your account" rel="facebox nofollow">
            <span class="octicon octicon-repo-forked"></span>
            Fork
          </a>
          <a href="/NREL/OpenStudio-Beopt/network" class="social-count">0</a>
        </li>

</ul>

        <h1 itemscope itemtype="http://data-vocabulary.org/Breadcrumb" class="entry-title private">
          <span class="mega-octicon octicon-lock"></span>
          <span class="author"><a href="/NREL" class="url fn" itemprop="url" rel="author"><span itemprop="title">NREL</span></a></span><!--
       --><span class="path-divider">/</span><!--
       --><strong><a href="/NREL/OpenStudio-Beopt" class="js-current-repository js-repo-home-link">OpenStudio-Beopt</a></strong>
            <span class="repo-private-label">private</span>

          <span class="page-context-loader">
            <img alt="" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
          </span>

        </h1>
      </div><!-- /.container -->
    </div><!-- /.repohead -->

    <div class="container">
      <div class="repository-with-sidebar repo-container new-discussion-timeline  ">
        <div class="repository-sidebar clearfix">
            
<div class="sunken-menu vertical-right repo-nav js-repo-nav js-repository-container-pjax js-octicon-loaders" data-issue-count-url="/NREL/OpenStudio-Beopt/issues/counts">
  <div class="sunken-menu-contents">
    <ul class="sunken-menu-group">
      <li class="tooltipped tooltipped-w" aria-label="Code">
        <a href="/NREL/OpenStudio-Beopt/tree/PSD" aria-label="Code" class="selected js-selected-navigation-item sunken-menu-item" data-hotkey="g c" data-pjax="true" data-selected-links="repo_source repo_downloads repo_commits repo_releases repo_tags repo_branches /NREL/OpenStudio-Beopt/tree/PSD">
          <span class="octicon octicon-code"></span> <span class="full-word">Code</span>
          <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>

        <li class="tooltipped tooltipped-w" aria-label="Issues">
          <a href="/NREL/OpenStudio-Beopt/issues" aria-label="Issues" class="js-selected-navigation-item sunken-menu-item js-disable-pjax" data-hotkey="g i" data-selected-links="repo_issues repo_labels repo_milestones /NREL/OpenStudio-Beopt/issues">
            <span class="octicon octicon-issue-opened"></span> <span class="full-word">Issues</span>
            <span class="js-issue-replace-counter"></span>
            <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>        </li>

      <li class="tooltipped tooltipped-w" aria-label="Pull Requests">
        <a href="/NREL/OpenStudio-Beopt/pulls" aria-label="Pull Requests" class="js-selected-navigation-item sunken-menu-item js-disable-pjax" data-hotkey="g p" data-selected-links="repo_pulls /NREL/OpenStudio-Beopt/pulls">
            <span class="octicon octicon-git-pull-request"></span> <span class="full-word">Pull Requests</span>
            <span class="js-pull-replace-counter"></span>
            <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>


        <li class="tooltipped tooltipped-w" aria-label="Wiki">
          <a href="/NREL/OpenStudio-Beopt/wiki" aria-label="Wiki" class="js-selected-navigation-item sunken-menu-item js-disable-pjax" data-hotkey="g w" data-selected-links="repo_wiki /NREL/OpenStudio-Beopt/wiki">
            <span class="octicon octicon-book"></span> <span class="full-word">Wiki</span>
            <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>        </li>
    </ul>
    <div class="sunken-menu-separator"></div>
    <ul class="sunken-menu-group">

      <li class="tooltipped tooltipped-w" aria-label="Pulse">
        <a href="/NREL/OpenStudio-Beopt/pulse/weekly" aria-label="Pulse" class="js-selected-navigation-item sunken-menu-item" data-pjax="true" data-selected-links="pulse /NREL/OpenStudio-Beopt/pulse/weekly">
          <span class="octicon octicon-pulse"></span> <span class="full-word">Pulse</span>
          <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>

      <li class="tooltipped tooltipped-w" aria-label="Graphs">
        <a href="/NREL/OpenStudio-Beopt/graphs" aria-label="Graphs" class="js-selected-navigation-item sunken-menu-item" data-pjax="true" data-selected-links="repo_graphs repo_contributors /NREL/OpenStudio-Beopt/graphs">
          <span class="octicon octicon-graph"></span> <span class="full-word">Graphs</span>
          <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>
    </ul>


  </div>
</div>

              <div class="only-with-full-nav">
                
  
<div class="clone-url open"
  data-protocol-type="http"
  data-url="/users/set_protocol?protocol_selector=http&amp;protocol_type=push">
  <h3><span class="text-emphasized">HTTPS</span> clone URL</h3>
  <div class="input-group">
    <input type="text" class="input-mini input-monospace js-url-field"
           value="https://github.com/NREL/OpenStudio-Beopt.git" readonly="readonly">
    <span class="input-group-button">
      <button aria-label="Copy to clipboard" class="js-zeroclipboard minibutton zeroclipboard-button" data-clipboard-text="https://github.com/NREL/OpenStudio-Beopt.git" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </span>
  </div>
</div>

  
<div class="clone-url "
  data-protocol-type="ssh"
  data-url="/users/set_protocol?protocol_selector=ssh&amp;protocol_type=push">
  <h3><span class="text-emphasized">SSH</span> clone URL</h3>
  <div class="input-group">
    <input type="text" class="input-mini input-monospace js-url-field"
           value="git@github.com:NREL/OpenStudio-Beopt.git" readonly="readonly">
    <span class="input-group-button">
      <button aria-label="Copy to clipboard" class="js-zeroclipboard minibutton zeroclipboard-button" data-clipboard-text="git@github.com:NREL/OpenStudio-Beopt.git" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </span>
  </div>
</div>

  
<div class="clone-url "
  data-protocol-type="subversion"
  data-url="/users/set_protocol?protocol_selector=subversion&amp;protocol_type=push">
  <h3><span class="text-emphasized">Subversion</span> checkout URL</h3>
  <div class="input-group">
    <input type="text" class="input-mini input-monospace js-url-field"
           value="https://github.com/NREL/OpenStudio-Beopt" readonly="readonly">
    <span class="input-group-button">
      <button aria-label="Copy to clipboard" class="js-zeroclipboard minibutton zeroclipboard-button" data-clipboard-text="https://github.com/NREL/OpenStudio-Beopt" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </span>
  </div>
</div>


<p class="clone-options">You can clone with
      <a href="#" class="js-clone-selector" data-protocol="http">HTTPS</a>,
      <a href="#" class="js-clone-selector" data-protocol="ssh">SSH</a>,
      or <a href="#" class="js-clone-selector" data-protocol="subversion">Subversion</a>.
  <a href="https://help.github.com/articles/which-remote-url-should-i-use" class="help tooltipped tooltipped-n" aria-label="Get help on which URL is right for you.">
    <span class="octicon octicon-question"></span>
  </a>
</p>


  <a href="http://windows.github.com" class="minibutton sidebar-button" title="Save NREL/OpenStudio-Beopt to your computer and use it in GitHub Desktop." aria-label="Save NREL/OpenStudio-Beopt to your computer and use it in GitHub Desktop.">
    <span class="octicon octicon-device-desktop"></span>
    Clone in Desktop
  </a>

                <a href="/NREL/OpenStudio-Beopt/archive/PSD.zip"
                   class="minibutton sidebar-button"
                   aria-label="Download the contents of NREL/OpenStudio-Beopt as a zip file"
                   title="Download the contents of NREL/OpenStudio-Beopt as a zip file"
                   rel="nofollow">
                  <span class="octicon octicon-cloud-download"></span>
                  Download ZIP
                </a>
              </div>
        </div><!-- /.repository-sidebar -->

        <div id="js-repo-pjax-container" class="repository-content context-loader-container" data-pjax-container>
          

<a href="/NREL/OpenStudio-Beopt/blob/f87dd61c90072905a44a0e815539ba0bcacafbd7/measures/ModifySiteWaterMainsTemperature/measure.rb" class="hidden js-permalink-shortcut" data-hotkey="y">Permalink</a>

<!-- blob contrib key: blob_contributors:v21:09ecada350edfe6caeb0faf4ff89a2c5 -->

<div class="file-navigation">
  
<div class="select-menu js-menu-container js-select-menu left">
  <span class="minibutton select-menu-button js-menu-target css-truncate" data-hotkey="w"
    data-master-branch="master"
    data-ref="PSD"
    title="PSD"
    role="button" aria-label="Switch branches or tags" tabindex="0" aria-haspopup="true">
    <span class="octicon octicon-git-branch"></span>
    <i>branch:</i>
    <span class="js-select-button css-truncate-target">PSD</span>
  </span>

  <div class="select-menu-modal-holder js-menu-content js-navigation-container" data-pjax aria-hidden="true">

    <div class="select-menu-modal">
      <div class="select-menu-header">
        <span class="select-menu-title">Switch branches/tags</span>
        <span class="octicon octicon-x js-menu-close" role="button" aria-label="Close"></span>
      </div> <!-- /.select-menu-header -->

      <div class="select-menu-filters">
        <div class="select-menu-text-filter">
          <input type="text" aria-label="Find or create a branch…" id="context-commitish-filter-field" class="js-filterable-field js-navigation-enable" placeholder="Find or create a branch…">
        </div>
        <div class="select-menu-tabs">
          <ul>
            <li class="select-menu-tab">
              <a href="#" data-tab-filter="branches" class="js-select-menu-tab">Branches</a>
            </li>
            <li class="select-menu-tab">
              <a href="#" data-tab-filter="tags" class="js-select-menu-tab">Tags</a>
            </li>
          </ul>
        </div><!-- /.select-menu-tabs -->
      </div><!-- /.select-menu-filters -->

      <div class="select-menu-list select-menu-tab-bucket js-select-menu-tab-bucket" data-tab-filter="branches">

        <div data-filterable-for="context-commitish-filter-field" data-filterable-type="substring">


            <div class="select-menu-item js-navigation-item selected">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/NREL/OpenStudio-Beopt/blob/PSD/measures/ModifySiteWaterMainsTemperature/measure.rb"
                 data-name="PSD"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="PSD">PSD</a>
            </div> <!-- /.select-menu-item -->
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/NREL/OpenStudio-Beopt/blob/master/measures/ModifySiteWaterMainsTemperature/measure.rb"
                 data-name="master"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="master">master</a>
            </div> <!-- /.select-menu-item -->
        </div>

          <form accept-charset="UTF-8" action="/NREL/OpenStudio-Beopt/branches" class="js-create-branch select-menu-item select-menu-new-item-form js-navigation-item js-new-item-form" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="QxLkv/Lc4eoKXul6Ay5fTmn5KqgCWEbfwk7iSDLRd6ThvBkrmt1c/36/YFGeFfxGlFTh9Wms6wJD5hZchDFRLA==" /></div>
            <span class="octicon octicon-git-branch select-menu-item-icon"></span>
            <div class="select-menu-item-text">
              <h4>Create branch: <span class="js-new-item-name"></span></h4>
              <span class="description">from ‘PSD’</span>
            </div>
            <input type="hidden" name="name" id="name" class="js-new-item-value">
            <input type="hidden" name="branch" id="branch" value="PSD">
            <input type="hidden" name="path" id="path" value="measures/ModifySiteWaterMainsTemperature/measure.rb">
          </form> <!-- /.select-menu-item -->

      </div> <!-- /.select-menu-list -->

      <div class="select-menu-list select-menu-tab-bucket js-select-menu-tab-bucket" data-tab-filter="tags">
        <div data-filterable-for="context-commitish-filter-field" data-filterable-type="substring">


        </div>

        <div class="select-menu-no-results">Nothing to show</div>
      </div> <!-- /.select-menu-list -->

    </div> <!-- /.select-menu-modal -->
  </div> <!-- /.select-menu-modal-holder -->
</div> <!-- /.select-menu -->

  <div class="button-group right">
    <a href="/NREL/OpenStudio-Beopt/find/PSD"
          class="js-show-file-finder minibutton empty-icon tooltipped tooltipped-s"
          data-pjax
          data-hotkey="t"
          aria-label="Quickly jump between files">
      <span class="octicon octicon-list-unordered"></span>
    </a>
    <button class="js-zeroclipboard minibutton zeroclipboard-button"
          data-clipboard-text="measures/ModifySiteWaterMainsTemperature/measure.rb"
          aria-label="Copy to clipboard"
          data-copied-hint="Copied!">
      <span class="octicon octicon-clippy"></span>
    </button>
  </div>

  <div class="breadcrumb">
    <span class='repo-root js-repo-root'><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/NREL/OpenStudio-Beopt/tree/PSD" class="" data-branch="PSD" data-direction="back" data-pjax="true" itemscope="url"><span itemprop="title">OpenStudio-Beopt</span></a></span></span><span class="separator"> / </span><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/NREL/OpenStudio-Beopt/tree/PSD/measures" class="" data-branch="PSD" data-direction="back" data-pjax="true" itemscope="url"><span itemprop="title">measures</span></a></span><span class="separator"> / </span><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/NREL/OpenStudio-Beopt/tree/PSD/measures/ModifySiteWaterMainsTemperature" class="" data-branch="PSD" data-direction="back" data-pjax="true" itemscope="url"><span itemprop="title">ModifySiteWaterMainsTemperature</span></a></span><span class="separator"> / </span><strong class="final-path">measure.rb</strong>
  </div>
</div>


  <div class="commit commit-loader file-history-tease js-deferred-content" data-url="/NREL/OpenStudio-Beopt/contributors/PSD/measures/ModifySiteWaterMainsTemperature/measure.rb">
    <div class="file-history-tease-header">
      Fetching contributors&hellip;
    </div>

    <div class="participation">
      <p class="loader-loading"><img alt="" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32-EAF2F5.gif" width="16" /></p>
      <p class="loader-error">Cannot retrieve contributors at this time</p>
    </div>
  </div>

<div class="file-box">
  <div class="file">
    <div class="meta clearfix">
      <div class="info file-name">
          <span>132 lines (93 sloc)</span>
          <span class="meta-divider"></span>
        <span>5.928 kb</span>
      </div>
      <div class="actions">
        <div class="button-group">
          <a href="/NREL/OpenStudio-Beopt/raw/PSD/measures/ModifySiteWaterMainsTemperature/measure.rb" class="minibutton " id="raw-url">Raw</a>
            <a href="/NREL/OpenStudio-Beopt/blame/PSD/measures/ModifySiteWaterMainsTemperature/measure.rb" class="minibutton js-update-url-with-hash">Blame</a>
          <a href="/NREL/OpenStudio-Beopt/commits/PSD/measures/ModifySiteWaterMainsTemperature/measure.rb" class="minibutton " rel="nofollow">History</a>
        </div><!-- /.button-group -->

          <a class="octicon-button tooltipped tooltipped-nw"
             href="http://windows.github.com" aria-label="Open this file in GitHub for Windows">
              <span class="octicon octicon-device-desktop"></span>
          </a>

              <a class="octicon-button js-update-url-with-hash"
                 href="/NREL/OpenStudio-Beopt/edit/PSD/measures/ModifySiteWaterMainsTemperature/measure.rb"
                 data-method="post" rel="nofollow" data-hotkey="e"><span class="octicon octicon-pencil"></span></a>

            <a class="octicon-button danger"
               href="/NREL/OpenStudio-Beopt/delete/PSD/measures/ModifySiteWaterMainsTemperature/measure.rb"
               data-method="post" data-test-id="delete-blob-file" rel="nofollow">
          <span class="octicon octicon-trashcan"></span>
        </a>
      </div><!-- /.actions -->
    </div>
    
  <div class="blob-wrapper data type-ruby">
      <table class="highlight tab-size-8 js-file-line-container">
      <tr>
        <td id="L1" class="blob-num js-line-number" data-line-number="1"></td>
        <td id="LC1" class="blob-code js-file-line"><span class="c1"># developed for use with Ruby 2.0.0 (have your Ruby evaluate RUBY_VERSION)</span></td>
      </tr>
      <tr>
        <td id="L2" class="blob-num js-line-number" data-line-number="2"></td>
        <td id="LC2" class="blob-code js-file-line"><span class="nb">require</span> <span class="s1">&#39;cgi&#39;</span></td>
      </tr>
      <tr>
        <td id="L3" class="blob-num js-line-number" data-line-number="3"></td>
        <td id="LC3" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L4" class="blob-num js-line-number" data-line-number="4"></td>
        <td id="LC4" class="blob-code js-file-line"><span class="k">class</span> <span class="nc">ModifySiteWaterMainsTemperature</span> <span class="o">&lt;</span> <span class="no">OpenStudio</span><span class="o">::</span><span class="no">Ruleset</span><span class="o">::</span><span class="no">ModelUserScript</span></td>
      </tr>
      <tr>
        <td id="L5" class="blob-num js-line-number" data-line-number="5"></td>
        <td id="LC5" class="blob-code js-file-line">  </td>
      </tr>
      <tr>
        <td id="L6" class="blob-num js-line-number" data-line-number="6"></td>
        <td id="LC6" class="blob-code js-file-line">  <span class="k">def</span> <span class="nf">name</span></td>
      </tr>
      <tr>
        <td id="L7" class="blob-num js-line-number" data-line-number="7"></td>
        <td id="LC7" class="blob-code js-file-line">    <span class="k">return</span> <span class="s2">&quot;ModifySiteWaterMainsTemperature&quot;</span></td>
      </tr>
      <tr>
        <td id="L8" class="blob-num js-line-number" data-line-number="8"></td>
        <td id="LC8" class="blob-code js-file-line">  <span class="k">end</span></td>
      </tr>
      <tr>
        <td id="L9" class="blob-num js-line-number" data-line-number="9"></td>
        <td id="LC9" class="blob-code js-file-line">  </td>
      </tr>
      <tr>
        <td id="L10" class="blob-num js-line-number" data-line-number="10"></td>
        <td id="LC10" class="blob-code js-file-line">  <span class="c1"># sets @avgOATarg and @maxDiffOATarg to our new arguments</span></td>
      </tr>
      <tr>
        <td id="L11" class="blob-num js-line-number" data-line-number="11"></td>
        <td id="LC11" class="blob-code js-file-line">  <span class="k">def</span> <span class="nf">arguments</span><span class="p">(</span><span class="n">model</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L12" class="blob-num js-line-number" data-line-number="12"></td>
        <td id="LC12" class="blob-code js-file-line">    <span class="n">args</span> <span class="o">=</span> <span class="no">OpenStudio</span><span class="o">::</span><span class="no">Ruleset</span><span class="o">::</span><span class="no">OSArgumentVector</span><span class="o">.</span><span class="n">new</span></td>
      </tr>
      <tr>
        <td id="L13" class="blob-num js-line-number" data-line-number="13"></td>
        <td id="LC13" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L14" class="blob-num js-line-number" data-line-number="14"></td>
        <td id="LC14" class="blob-code js-file-line">    <span class="c1">#Average Annual Outdoor Air Temp</span></td>
      </tr>
      <tr>
        <td id="L15" class="blob-num js-line-number" data-line-number="15"></td>
        <td id="LC15" class="blob-code js-file-line">    <span class="vi">@avgOATarg</span> <span class="o">=</span> <span class="no">OpenStudio</span><span class="o">::</span><span class="no">Ruleset</span><span class="o">::</span><span class="no">OSArgument</span><span class="o">::</span><span class="n">makeDoubleArgument</span><span class="p">(</span><span class="s2">&quot;avgOAT&quot;</span><span class="p">,</span><span class="kp">true</span><span class="p">)</span> <span class="c1"># true means required</span></td>
      </tr>
      <tr>
        <td id="L16" class="blob-num js-line-number" data-line-number="16"></td>
        <td id="LC16" class="blob-code js-file-line">    <span class="vi">@avgOATarg</span><span class="o">.</span><span class="n">setDisplayName</span><span class="p">(</span><span class="s2">&quot;Avg Annual Outdoor Air Temperature (?F)&quot;</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L17" class="blob-num js-line-number" data-line-number="17"></td>
        <td id="LC17" class="blob-code js-file-line">    <span class="vi">@avgOATarg</span><span class="o">.</span><span class="n">setDefaultValue</span><span class="p">(</span><span class="mi">50</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L18" class="blob-num js-line-number" data-line-number="18"></td>
        <td id="LC18" class="blob-code js-file-line">    <span class="n">args</span> <span class="o">&lt;&lt;</span> <span class="vi">@avgOATarg</span></td>
      </tr>
      <tr>
        <td id="L19" class="blob-num js-line-number" data-line-number="19"></td>
        <td id="LC19" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L20" class="blob-num js-line-number" data-line-number="20"></td>
        <td id="LC20" class="blob-code js-file-line">    <span class="c1">#Maximum Difference in Monthly Outdoor Air Temp</span></td>
      </tr>
      <tr>
        <td id="L21" class="blob-num js-line-number" data-line-number="21"></td>
        <td id="LC21" class="blob-code js-file-line">    <span class="vi">@maxDiffOATarg</span> <span class="o">=</span> <span class="no">OpenStudio</span><span class="o">::</span><span class="no">Ruleset</span><span class="o">::</span><span class="no">OSArgument</span><span class="o">::</span><span class="n">makeDoubleArgument</span><span class="p">(</span><span class="s2">&quot;maxDiffOAT&quot;</span><span class="p">,</span><span class="kp">true</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L22" class="blob-num js-line-number" data-line-number="22"></td>
        <td id="LC22" class="blob-code js-file-line">    <span class="vi">@maxDiffOATarg</span><span class="o">.</span><span class="n">setDisplayName</span><span class="p">(</span><span class="s2">&quot;Max Difference in Monthly Outdoor Air Temp (?F)&quot;</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L23" class="blob-num js-line-number" data-line-number="23"></td>
        <td id="LC23" class="blob-code js-file-line">    <span class="vi">@maxDiffOATarg</span><span class="o">.</span><span class="n">setDefaultValue</span><span class="p">(</span><span class="mi">30</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L24" class="blob-num js-line-number" data-line-number="24"></td>
        <td id="LC24" class="blob-code js-file-line">    <span class="n">args</span> <span class="o">&lt;&lt;</span> <span class="vi">@maxDiffOATarg</span></td>
      </tr>
      <tr>
        <td id="L25" class="blob-num js-line-number" data-line-number="25"></td>
        <td id="LC25" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L26" class="blob-num js-line-number" data-line-number="26"></td>
        <td id="LC26" class="blob-code js-file-line">    <span class="k">return</span> <span class="n">args</span></td>
      </tr>
      <tr>
        <td id="L27" class="blob-num js-line-number" data-line-number="27"></td>
        <td id="LC27" class="blob-code js-file-line">  <span class="k">end</span> <span class="c1"># arguments </span></td>
      </tr>
      <tr>
        <td id="L28" class="blob-num js-line-number" data-line-number="28"></td>
        <td id="LC28" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L29" class="blob-num js-line-number" data-line-number="29"></td>
        <td id="LC29" class="blob-code js-file-line">  <span class="c1">#Put argument values in @avgOAT and @maxDiffOAT, returning true if they validate, false otherwise</span></td>
      </tr>
      <tr>
        <td id="L30" class="blob-num js-line-number" data-line-number="30"></td>
        <td id="LC30" class="blob-code js-file-line">  <span class="c1">#(UserScript should exit(return false) if false is returned, like with registerWarning)</span></td>
      </tr>
      <tr>
        <td id="L31" class="blob-num js-line-number" data-line-number="31"></td>
        <td id="LC31" class="blob-code js-file-line">  <span class="k">def</span> <span class="nf">prevalidate</span><span class="p">(</span><span class="n">model</span><span class="p">,</span> <span class="n">runner</span><span class="p">,</span> <span class="n">user_arguments</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L32" class="blob-num js-line-number" data-line-number="32"></td>
        <td id="LC32" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L33" class="blob-num js-line-number" data-line-number="33"></td>
        <td id="LC33" class="blob-code js-file-line">    <span class="n">modelArgs</span> <span class="o">=</span> <span class="n">arguments</span><span class="p">(</span><span class="n">model</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L34" class="blob-num js-line-number" data-line-number="34"></td>
        <td id="LC34" class="blob-code js-file-line">  </td>
      </tr>
      <tr>
        <td id="L35" class="blob-num js-line-number" data-line-number="35"></td>
        <td id="LC35" class="blob-code js-file-line">    <span class="c1">#use the built-in error checking </span></td>
      </tr>
      <tr>
        <td id="L36" class="blob-num js-line-number" data-line-number="36"></td>
        <td id="LC36" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="n">runner</span><span class="o">.</span><span class="n">validateUserArguments</span><span class="p">(</span><span class="n">modelArgs</span><span class="p">,</span> <span class="n">user_arguments</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L37" class="blob-num js-line-number" data-line-number="37"></td>
        <td id="LC37" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L38" class="blob-num js-line-number" data-line-number="38"></td>
        <td id="LC38" class="blob-code js-file-line">    <span class="c1">#isolate relevant user argument values</span></td>
      </tr>
      <tr>
        <td id="L39" class="blob-num js-line-number" data-line-number="39"></td>
        <td id="LC39" class="blob-code js-file-line">    <span class="vi">@avgOAT</span> <span class="o">=</span> <span class="n">runner</span><span class="o">.</span><span class="n">getDoubleArgumentValue</span><span class="p">(</span><span class="s2">&quot;avgOAT&quot;</span><span class="p">,</span><span class="n">user_arguments</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L40" class="blob-num js-line-number" data-line-number="40"></td>
        <td id="LC40" class="blob-code js-file-line">    <span class="vi">@maxDiffOAT</span> <span class="o">=</span> <span class="n">runner</span><span class="o">.</span><span class="n">getDoubleArgumentValue</span><span class="p">(</span><span class="s2">&quot;maxDiffOAT&quot;</span><span class="p">,</span><span class="n">user_arguments</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L41" class="blob-num js-line-number" data-line-number="41"></td>
        <td id="LC41" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L42" class="blob-num js-line-number" data-line-number="42"></td>
        <td id="LC42" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L43" class="blob-num js-line-number" data-line-number="43"></td>
        <td id="LC43" class="blob-code js-file-line">    <span class="c1">#CHECK for INVALID arguments</span></td>
      </tr>
      <tr>
        <td id="L44" class="blob-num js-line-number" data-line-number="44"></td>
        <td id="LC44" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L45" class="blob-num js-line-number" data-line-number="45"></td>
        <td id="LC45" class="blob-code js-file-line">    <span class="c1">#&quot;UserScripts should return false after calling [registerError]&quot; see http://openstudio.nrel.gov/c-sdk-documentation/ruleset</span></td>
      </tr>
      <tr>
        <td id="L46" class="blob-num js-line-number" data-line-number="46"></td>
        <td id="LC46" class="blob-code js-file-line">    <span class="n">emit</span> <span class="o">=</span> <span class="nb">lambda</span><span class="p">{</span><span class="o">|</span><span class="n">msg</span><span class="o">|</span> <span class="n">runner</span><span class="o">.</span><span class="n">registerError</span><span class="p">(</span><span class="no">CGI</span><span class="o">.</span><span class="n">escapeHTML</span><span class="p">(</span><span class="n">msg</span> <span class="o">+</span><span class="s2">&quot; -- please resubmit&quot;</span><span class="p">))</span> <span class="p">;</span>  <span class="kp">false</span>  <span class="p">}</span></td>
      </tr>
      <tr>
        <td id="L47" class="blob-num js-line-number" data-line-number="47"></td>
        <td id="LC47" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L48" class="blob-num js-line-number" data-line-number="48"></td>
        <td id="LC48" class="blob-code js-file-line">    <span class="n">avgOATMax</span> <span class="o">=</span> <span class="mi">85</span><span class="p">;</span></td>
      </tr>
      <tr>
        <td id="L49" class="blob-num js-line-number" data-line-number="49"></td>
        <td id="LC49" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="vi">@avgOAT</span> <span class="o">&lt;=</span> <span class="n">avgOATMax</span> <span class="ow">or</span> <span class="n">emit</span><span class="o">[</span><span class="s2">&quot;Temperature </span><span class="si">#{</span><span class="vi">@avgOAT</span><span class="si">}</span><span class="s2">F too high (&gt;</span><span class="si">#{</span><span class="n">avgOATMax</span><span class="si">}</span><span class="s2">)&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L50" class="blob-num js-line-number" data-line-number="50"></td>
        <td id="LC50" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L51" class="blob-num js-line-number" data-line-number="51"></td>
        <td id="LC51" class="blob-code js-file-line">    <span class="n">avgOATMin</span> <span class="o">=</span> <span class="o">-</span><span class="mi">70</span><span class="p">;</span></td>
      </tr>
      <tr>
        <td id="L52" class="blob-num js-line-number" data-line-number="52"></td>
        <td id="LC52" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="n">avgOATMin</span> <span class="o">&lt;=</span> <span class="vi">@avgOAT</span> <span class="ow">or</span> <span class="n">emit</span><span class="o">[</span><span class="s2">&quot;Temperature </span><span class="si">#{</span><span class="vi">@avgOAT</span><span class="si">}</span><span class="s2">F too low (&lt;</span><span class="si">#{</span><span class="n">avgOATMin</span><span class="si">}</span><span class="s2">)&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L53" class="blob-num js-line-number" data-line-number="53"></td>
        <td id="LC53" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L54" class="blob-num js-line-number" data-line-number="54"></td>
        <td id="LC54" class="blob-code js-file-line">    <span class="n">maxDiffOATMax</span> <span class="o">=</span> <span class="mi">40</span><span class="p">;</span></td>
      </tr>
      <tr>
        <td id="L55" class="blob-num js-line-number" data-line-number="55"></td>
        <td id="LC55" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="vi">@maxDiffOAT</span> <span class="o">&lt;=</span> <span class="n">maxDiffOATMax</span> <span class="ow">or</span> <span class="n">emit</span><span class="o">[</span><span class="s2">&quot;Temperature Diff </span><span class="si">#{</span><span class="vi">@maxDiffOAT</span><span class="si">}</span><span class="s2">F too high (&gt;</span><span class="si">#{</span><span class="n">maxDiffOATMax</span><span class="si">}</span><span class="s2">)&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L56" class="blob-num js-line-number" data-line-number="56"></td>
        <td id="LC56" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L57" class="blob-num js-line-number" data-line-number="57"></td>
        <td id="LC57" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="mi">0</span> <span class="o">&lt;=</span> <span class="vi">@maxDiffOAT</span> <span class="ow">or</span> <span class="n">emit</span><span class="o">[</span><span class="s2">&quot;Temperature Diff </span><span class="si">#{</span><span class="vi">@maxDiffOAT</span><span class="si">}</span><span class="s2">F must not be negative&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L58" class="blob-num js-line-number" data-line-number="58"></td>
        <td id="LC58" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L59" class="blob-num js-line-number" data-line-number="59"></td>
        <td id="LC59" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L60" class="blob-num js-line-number" data-line-number="60"></td>
        <td id="LC60" class="blob-code js-file-line">    <span class="c1">#CHECK for VALID-BUT-IFFY arguments</span></td>
      </tr>
      <tr>
        <td id="L61" class="blob-num js-line-number" data-line-number="61"></td>
        <td id="LC61" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L62" class="blob-num js-line-number" data-line-number="62"></td>
        <td id="LC62" class="blob-code js-file-line">    <span class="c1">#&quot;The UserScript should exit (return false) if false is returned [from registerWarning]&quot; see http://openstudio.nrel.gov/c-sdk-documentation/ruleset</span></td>
      </tr>
      <tr>
        <td id="L63" class="blob-num js-line-number" data-line-number="63"></td>
        <td id="LC63" class="blob-code js-file-line">    <span class="n">emit</span> <span class="o">=</span> <span class="nb">lambda</span><span class="p">{</span><span class="o">|</span><span class="n">msg</span><span class="o">|</span> <span class="n">runner</span><span class="o">.</span><span class="n">registerWarning</span><span class="p">(</span><span class="no">CGI</span><span class="o">.</span><span class="n">escapeHTML</span><span class="p">(</span><span class="n">msg</span><span class="p">))</span> <span class="p">}</span> </td>
      </tr>
      <tr>
        <td id="L64" class="blob-num js-line-number" data-line-number="64"></td>
        <td id="LC64" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L65" class="blob-num js-line-number" data-line-number="65"></td>
        <td id="LC65" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="vi">@avgOAT</span> <span class="o">!=</span> <span class="vi">@avgOATarg</span><span class="o">.</span><span class="n">defaultValueAsDouble</span> <span class="ow">or</span> <span class="n">emit</span><span class="o">[</span><span class="s2">&quot;Using default Average temp (</span><span class="si">#{</span><span class="vi">@avgOAT</span><span class="si">}</span><span class="s2">F)&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L66" class="blob-num js-line-number" data-line-number="66"></td>
        <td id="LC66" class="blob-code js-file-line">   </td>
      </tr>
      <tr>
        <td id="L67" class="blob-num js-line-number" data-line-number="67"></td>
        <td id="LC67" class="blob-code js-file-line">    <span class="n">avgOATRatherHigh</span> <span class="o">=</span> <span class="mi">70</span></td>
      </tr>
      <tr>
        <td id="L68" class="blob-num js-line-number" data-line-number="68"></td>
        <td id="LC68" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="vi">@avgOAT</span> <span class="o">&lt;=</span> <span class="n">avgOATRatherHigh</span> <span class="ow">or</span> <span class="n">emit</span><span class="o">[</span><span class="s2">&quot;Temperature </span><span class="si">#{</span><span class="vi">@avgOAT</span><span class="si">}</span><span class="s2">F is rather high (&gt;</span><span class="si">#{</span><span class="n">avgOATRatherHigh</span><span class="si">}</span><span class="s2">)&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L69" class="blob-num js-line-number" data-line-number="69"></td>
        <td id="LC69" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L70" class="blob-num js-line-number" data-line-number="70"></td>
        <td id="LC70" class="blob-code js-file-line">    <span class="n">avgOATRatherLow</span> <span class="o">=</span> <span class="o">-</span><span class="mi">40</span></td>
      </tr>
      <tr>
        <td id="L71" class="blob-num js-line-number" data-line-number="71"></td>
        <td id="LC71" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="n">avgOATRatherLow</span> <span class="o">&lt;=</span> <span class="vi">@avgOAT</span> <span class="ow">or</span> <span class="n">emit</span><span class="o">[</span><span class="s2">&quot;Temperature </span><span class="si">#{</span><span class="vi">@avgOAT</span><span class="si">}</span><span class="s2">F is rather low (&lt;</span><span class="si">#{</span><span class="n">avgOATRatherLow</span><span class="si">}</span><span class="s2">)&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L72" class="blob-num js-line-number" data-line-number="72"></td>
        <td id="LC72" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L73" class="blob-num js-line-number" data-line-number="73"></td>
        <td id="LC73" class="blob-code js-file-line">    <span class="n">maxDiffOATRatherHigh</span> <span class="o">=</span> <span class="mi">30</span></td>
      </tr>
      <tr>
        <td id="L74" class="blob-num js-line-number" data-line-number="74"></td>
        <td id="LC74" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="vi">@maxDiffOAT</span> <span class="o">&lt;=</span> <span class="n">maxDiffOATRatherHigh</span> <span class="ow">or</span> <span class="n">emit</span><span class="o">[</span><span class="s2">&quot;Temperature Diff </span><span class="si">#{</span><span class="vi">@maxDiffOAT</span><span class="si">}</span><span class="s2">F is rather high (&gt;</span><span class="si">#{</span><span class="n">maxDiffOATRatherHigh</span><span class="si">}</span><span class="s2">)&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L75" class="blob-num js-line-number" data-line-number="75"></td>
        <td id="LC75" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L76" class="blob-num js-line-number" data-line-number="76"></td>
        <td id="LC76" class="blob-code js-file-line">    <span class="kp">true</span></td>
      </tr>
      <tr>
        <td id="L77" class="blob-num js-line-number" data-line-number="77"></td>
        <td id="LC77" class="blob-code js-file-line">  <span class="k">end</span> <span class="c1"># prevalidate</span></td>
      </tr>
      <tr>
        <td id="L78" class="blob-num js-line-number" data-line-number="78"></td>
        <td id="LC78" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L79" class="blob-num js-line-number" data-line-number="79"></td>
        <td id="LC79" class="blob-code js-file-line">  <span class="k">def</span> <span class="nf">run</span><span class="p">(</span><span class="n">model</span><span class="p">,</span> <span class="n">runner</span><span class="p">,</span> <span class="n">user_arguments</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L80" class="blob-num js-line-number" data-line-number="80"></td>
        <td id="LC80" class="blob-code js-file-line">    <span class="k">super</span><span class="p">(</span><span class="n">model</span><span class="p">,</span> <span class="n">runner</span><span class="p">,</span> <span class="n">user_arguments</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L81" class="blob-num js-line-number" data-line-number="81"></td>
        <td id="LC81" class="blob-code js-file-line">  </td>
      </tr>
      <tr>
        <td id="L82" class="blob-num js-line-number" data-line-number="82"></td>
        <td id="LC82" class="blob-code js-file-line">    <span class="k">return</span> <span class="kp">false</span> <span class="k">unless</span> <span class="n">prevalidate</span><span class="p">(</span><span class="n">model</span><span class="p">,</span> <span class="n">runner</span><span class="p">,</span> <span class="n">user_arguments</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L83" class="blob-num js-line-number" data-line-number="83"></td>
        <td id="LC83" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L84" class="blob-num js-line-number" data-line-number="84"></td>
        <td id="LC84" class="blob-code js-file-line">    <span class="n">waterUseEquipment</span>  <span class="o">=</span> <span class="no">Hash</span><span class="o">[</span><span class="ss">:count</span><span class="o">=&gt;</span> <span class="n">model</span><span class="o">.</span><span class="n">getWaterUseEquipments</span><span class="o">.</span><span class="n">length</span>   <span class="p">,</span> <span class="ss">:display</span><span class="o">=&gt;</span> <span class="s2">&quot;Water Use Equipment&quot;</span> <span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L85" class="blob-num js-line-number" data-line-number="85"></td>
        <td id="LC85" class="blob-code js-file-line">    <span class="n">waterUseConnection</span> <span class="o">=</span> <span class="no">Hash</span><span class="o">[</span><span class="ss">:count</span><span class="o">=&gt;</span> <span class="n">model</span><span class="o">.</span><span class="n">getWaterUseConnectionss</span><span class="o">.</span><span class="n">length</span> <span class="p">,</span> <span class="ss">:display</span><span class="o">=&gt;</span> <span class="s2">&quot;Water Use Connections&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L86" class="blob-num js-line-number" data-line-number="86"></td>
        <td id="LC86" class="blob-code js-file-line">    <span class="n">waterHeaterMixed</span>   <span class="o">=</span> <span class="no">Hash</span><span class="o">[</span><span class="ss">:count</span><span class="o">=&gt;</span> <span class="n">model</span><span class="o">.</span><span class="n">getWaterHeaterMixeds</span><span class="o">.</span><span class="n">length</span>    <span class="p">,</span> <span class="ss">:display</span><span class="o">=&gt;</span> <span class="s2">&quot;Water Heaters (Mixed)&quot;</span><span class="o">]</span></td>
      </tr>
      <tr>
        <td id="L87" class="blob-num js-line-number" data-line-number="87"></td>
        <td id="LC87" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L88" class="blob-num js-line-number" data-line-number="88"></td>
        <td id="LC88" class="blob-code js-file-line">    <span class="n">displayCount</span> <span class="o">=</span> <span class="nb">lambda</span><span class="p">{</span><span class="o">|</span><span class="n">x</span><span class="o">|</span> <span class="s2">&quot;</span><span class="si">#{</span><span class="n">x</span><span class="o">[</span><span class="ss">:count</span><span class="o">]</span><span class="si">}</span><span class="s2"> </span><span class="si">#{</span><span class="n">x</span><span class="o">[</span><span class="ss">:display</span><span class="o">]</span><span class="si">}</span><span class="s2">&quot;</span><span class="p">}</span></td>
      </tr>
      <tr>
        <td id="L89" class="blob-num js-line-number" data-line-number="89"></td>
        <td id="LC89" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L90" class="blob-num js-line-number" data-line-number="90"></td>
        <td id="LC90" class="blob-code js-file-line">    <span class="n">runner</span><span class="o">.</span><span class="n">registerInitialCondition</span> <span class="no">CGI</span><span class="o">.</span><span class="n">escapeHTML</span><span class="p">(</span></td>
      </tr>
      <tr>
        <td id="L91" class="blob-num js-line-number" data-line-number="91"></td>
        <td id="LC91" class="blob-code js-file-line">                                    <span class="s2">&quot;Initially there were </span><span class="si">#{</span><span class="n">displayCount</span><span class="o">[</span><span class="n">waterUseEquipment</span><span class="o">]</span><span class="si">}</span><span class="s2">&quot;</span><span class="o">+</span></td>
      </tr>
      <tr>
        <td id="L92" class="blob-num js-line-number" data-line-number="92"></td>
        <td id="LC92" class="blob-code js-file-line">                                    <span class="s2">&quot;, </span><span class="si">#{</span><span class="n">displayCount</span><span class="o">[</span><span class="n">waterHeaterMixed</span><span class="o">]</span><span class="si">}</span><span class="s2">&quot;</span><span class="o">+</span></td>
      </tr>
      <tr>
        <td id="L93" class="blob-num js-line-number" data-line-number="93"></td>
        <td id="LC93" class="blob-code js-file-line">                                    <span class="s2">&quot;, and </span><span class="si">#{</span><span class="n">displayCount</span><span class="o">[</span><span class="n">waterUseConnection</span><span class="o">]</span><span class="si">}</span><span class="s2">&quot;</span> </td>
      </tr>
      <tr>
        <td id="L94" class="blob-num js-line-number" data-line-number="94"></td>
        <td id="LC94" class="blob-code js-file-line">                                    <span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L95" class="blob-num js-line-number" data-line-number="95"></td>
        <td id="LC95" class="blob-code js-file-line">     </td>
      </tr>
      <tr>
        <td id="L96" class="blob-num js-line-number" data-line-number="96"></td>
        <td id="LC96" class="blob-code js-file-line">    <span class="k">if</span> <span class="p">(</span><span class="mi">0</span><span class="o">==</span> <span class="n">waterUseEquipment</span><span class="o">[</span><span class="ss">:count</span><span class="o">]</span> <span class="o">+</span><span class="n">waterUseConnection</span><span class="o">[</span><span class="ss">:count</span><span class="o">]</span> <span class="o">+</span><span class="n">waterHeaterMixed</span><span class="o">[</span><span class="ss">:count</span><span class="o">]</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L97" class="blob-num js-line-number" data-line-number="97"></td>
        <td id="LC97" class="blob-code js-file-line">        <span class="n">runner</span><span class="o">.</span><span class="n">registerAsNotApplicable</span> <span class="no">CGI</span><span class="o">.</span><span class="n">escapeHTML</span><span class="p">(</span></td>
      </tr>
      <tr>
        <td id="L98" class="blob-num js-line-number" data-line-number="98"></td>
        <td id="LC98" class="blob-code js-file-line">                                       <span class="s2">&quot;SiteWaterMainsTemperature was not updated, since there was&quot;</span><span class="o">+</span></td>
      </tr>
      <tr>
        <td id="L99" class="blob-num js-line-number" data-line-number="99"></td>
        <td id="LC99" class="blob-code js-file-line">                                       <span class="s2">&quot; no </span><span class="si">#{</span><span class="n">waterUseEquipment</span><span class="o">[</span><span class="ss">:display</span><span class="o">]</span><span class="si">}</span><span class="s2">&quot;</span><span class="o">+</span></td>
      </tr>
      <tr>
        <td id="L100" class="blob-num js-line-number" data-line-number="100"></td>
        <td id="LC100" class="blob-code js-file-line">                                       <span class="s2">&quot;, no </span><span class="si">#{</span><span class="n">waterHeaterMixed</span><span class="o">[</span><span class="ss">:display</span><span class="o">]</span><span class="si">}</span><span class="s2">&quot;</span><span class="o">+</span></td>
      </tr>
      <tr>
        <td id="L101" class="blob-num js-line-number" data-line-number="101"></td>
        <td id="LC101" class="blob-code js-file-line">                                       <span class="s2">&quot;, and no </span><span class="si">#{</span><span class="n">waterUseConnection</span><span class="o">[</span><span class="ss">:display</span><span class="o">]</span><span class="si">}</span><span class="s2">&quot;</span></td>
      </tr>
      <tr>
        <td id="L102" class="blob-num js-line-number" data-line-number="102"></td>
        <td id="LC102" class="blob-code js-file-line">                                       <span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L103" class="blob-num js-line-number" data-line-number="103"></td>
        <td id="LC103" class="blob-code js-file-line">    <span class="k">else</span></td>
      </tr>
      <tr>
        <td id="L104" class="blob-num js-line-number" data-line-number="104"></td>
        <td id="LC104" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L105" class="blob-num js-line-number" data-line-number="105"></td>
        <td id="LC105" class="blob-code js-file-line">        <span class="n">swmt</span> <span class="o">=</span> <span class="n">model</span><span class="o">.</span><span class="n">getSiteWaterMainsTemperature</span></td>
      </tr>
      <tr>
        <td id="L106" class="blob-num js-line-number" data-line-number="106"></td>
        <td id="LC106" class="blob-code js-file-line">        </td>
      </tr>
      <tr>
        <td id="L107" class="blob-num js-line-number" data-line-number="107"></td>
        <td id="LC107" class="blob-code js-file-line">        <span class="n">swmt</span><span class="o">.</span><span class="n">setCalculationMethod</span> <span class="s2">&quot;Correlation&quot;</span></td>
      </tr>
      <tr>
        <td id="L108" class="blob-num js-line-number" data-line-number="108"></td>
        <td id="LC108" class="blob-code js-file-line">        <span class="n">swmt</span><span class="o">.</span><span class="n">setAnnualAverageOutdoorAirTemperature</span> <span class="n">tempCfromF</span><span class="p">(</span><span class="vi">@avgOAT</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L109" class="blob-num js-line-number" data-line-number="109"></td>
        <td id="LC109" class="blob-code js-file-line">        <span class="n">swmt</span><span class="o">.</span><span class="n">setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures</span>  <span class="n">tempDiffCfromF</span><span class="p">(</span><span class="vi">@maxDiffOAT</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L110" class="blob-num js-line-number" data-line-number="110"></td>
        <td id="LC110" class="blob-code js-file-line">        </td>
      </tr>
      <tr>
        <td id="L111" class="blob-num js-line-number" data-line-number="111"></td>
        <td id="LC111" class="blob-code js-file-line">        <span class="n">runner</span><span class="o">.</span><span class="n">registerFinalCondition</span> <span class="no">CGI</span><span class="o">.</span><span class="n">escapeHTML</span><span class="p">(</span></td>
      </tr>
      <tr>
        <td id="L112" class="blob-num js-line-number" data-line-number="112"></td>
        <td id="LC112" class="blob-code js-file-line">                                      <span class="s2">&quot;SiteWaterMainsTemperature has been updated with&quot;</span><span class="o">+</span></td>
      </tr>
      <tr>
        <td id="L113" class="blob-num js-line-number" data-line-number="113"></td>
        <td id="LC113" class="blob-code js-file-line">                                      <span class="s2">&quot; Avg Temperature </span><span class="si">#{</span><span class="vi">@avgOAT</span><span class="si">}</span><span class="s2">F (</span><span class="si">#{</span><span class="n">swmt</span><span class="o">.</span><span class="n">annualAverageOutdoorAirTemperature</span><span class="o">.</span><span class="n">get</span><span class="o">.</span><span class="n">round</span><span class="p">(</span><span class="mi">1</span><span class="p">)</span><span class="si">}</span><span class="s2">C)&quot;</span><span class="o">+</span></td>
      </tr>
      <tr>
        <td id="L114" class="blob-num js-line-number" data-line-number="114"></td>
        <td id="LC114" class="blob-code js-file-line">                                      <span class="s2">&quot; and Max Diff </span><span class="si">#{</span><span class="vi">@maxDiffOAT</span><span class="si">}</span><span class="s2">F (</span><span class="si">#{</span><span class="n">swmt</span><span class="o">.</span><span class="n">maximumDifferenceInMonthlyAverageOutdoorAirTemperatures</span><span class="o">.</span><span class="n">get</span><span class="o">.</span><span class="n">round</span><span class="p">(</span><span class="mi">1</span><span class="p">)</span><span class="si">}</span><span class="s2">C)&quot;</span></td>
      </tr>
      <tr>
        <td id="L115" class="blob-num js-line-number" data-line-number="115"></td>
        <td id="LC115" class="blob-code js-file-line">                                      <span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L116" class="blob-num js-line-number" data-line-number="116"></td>
        <td id="LC116" class="blob-code js-file-line">    <span class="k">end</span></td>
      </tr>
      <tr>
        <td id="L117" class="blob-num js-line-number" data-line-number="117"></td>
        <td id="LC117" class="blob-code js-file-line">    </td>
      </tr>
      <tr>
        <td id="L118" class="blob-num js-line-number" data-line-number="118"></td>
        <td id="LC118" class="blob-code js-file-line">    <span class="kp">true</span></td>
      </tr>
      <tr>
        <td id="L119" class="blob-num js-line-number" data-line-number="119"></td>
        <td id="LC119" class="blob-code js-file-line">  <span class="k">end</span> <span class="c1"># run </span></td>
      </tr>
      <tr>
        <td id="L120" class="blob-num js-line-number" data-line-number="120"></td>
        <td id="LC120" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L121" class="blob-num js-line-number" data-line-number="121"></td>
        <td id="LC121" class="blob-code js-file-line">  <span class="k">def</span> <span class="nf">tempCfromF</span><span class="p">(</span><span class="n">x</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L122" class="blob-num js-line-number" data-line-number="122"></td>
        <td id="LC122" class="blob-code js-file-line">    <span class="no">OpenStudio</span><span class="o">::</span><span class="n">convert</span><span class="p">(</span><span class="n">x</span><span class="o">*</span><span class="mi">1</span><span class="o">.</span><span class="mi">0</span><span class="p">,</span><span class="s2">&quot;F&quot;</span><span class="p">,</span><span class="s2">&quot;C&quot;</span><span class="p">)</span><span class="o">.</span><span class="n">get</span></td>
      </tr>
      <tr>
        <td id="L123" class="blob-num js-line-number" data-line-number="123"></td>
        <td id="LC123" class="blob-code js-file-line">  <span class="k">end</span></td>
      </tr>
      <tr>
        <td id="L124" class="blob-num js-line-number" data-line-number="124"></td>
        <td id="LC124" class="blob-code js-file-line">  </td>
      </tr>
      <tr>
        <td id="L125" class="blob-num js-line-number" data-line-number="125"></td>
        <td id="LC125" class="blob-code js-file-line">  <span class="k">def</span> <span class="nf">tempDiffCfromF</span><span class="p">(</span><span class="n">d</span><span class="p">)</span> <span class="c1">#if d is the difference between two temps in F, then tempDiffCfromF(d) is the difference between the temps in C</span></td>
      </tr>
      <tr>
        <td id="L126" class="blob-num js-line-number" data-line-number="126"></td>
        <td id="LC126" class="blob-code js-file-line">    <span class="n">tempCfromF</span><span class="p">(</span><span class="n">d</span><span class="p">)</span> <span class="o">-</span><span class="n">tempCfromF</span><span class="p">(</span><span class="mi">0</span><span class="p">)</span></td>
      </tr>
      <tr>
        <td id="L127" class="blob-num js-line-number" data-line-number="127"></td>
        <td id="LC127" class="blob-code js-file-line">  <span class="k">end</span></td>
      </tr>
      <tr>
        <td id="L128" class="blob-num js-line-number" data-line-number="128"></td>
        <td id="LC128" class="blob-code js-file-line">  </td>
      </tr>
      <tr>
        <td id="L129" class="blob-num js-line-number" data-line-number="129"></td>
        <td id="LC129" class="blob-code js-file-line"><span class="k">end</span> <span class="c1"># ModifySiteWaterMainsTemperature</span></td>
      </tr>
      <tr>
        <td id="L130" class="blob-num js-line-number" data-line-number="130"></td>
        <td id="LC130" class="blob-code js-file-line">
</td>
      </tr>
      <tr>
        <td id="L131" class="blob-num js-line-number" data-line-number="131"></td>
        <td id="LC131" class="blob-code js-file-line"><span class="c1">#this allows the measure to be use by the application</span></td>
      </tr>
      <tr>
        <td id="L132" class="blob-num js-line-number" data-line-number="132"></td>
        <td id="LC132" class="blob-code js-file-line"><span class="no">ModifySiteWaterMainsTemperature</span><span class="o">.</span><span class="n">new</span><span class="o">.</span><span class="n">registerWithApplication</span></td>
      </tr>
</table>

  </div>

  </div>
</div>

<a href="#jump-to-line" rel="facebox[.linejump]" data-hotkey="l" style="display:none">Jump to Line</a>
<div id="jump-to-line" style="display:none">
  <form accept-charset="UTF-8" class="js-jump-to-line-form">
    <input class="linejump-input js-jump-to-line-field" type="text" placeholder="Jump to line&hellip;" autofocus>
    <button type="submit" class="button">Go</button>
  </form>
</div>

        </div>

      </div><!-- /.repo-container -->
      <div class="modal-backdrop"></div>
    </div><!-- /.container -->
  </div><!-- /.site -->


    </div><!-- /.wrapper -->

      <div class="container">
  <div class="site-footer">
    <ul class="site-footer-links right">
      <li><a href="https://status.github.com/">Status</a></li>
      <li><a href="http://developer.github.com">API</a></li>
      <li><a href="http://training.github.com">Training</a></li>
      <li><a href="http://shop.github.com">Shop</a></li>
      <li><a href="/blog">Blog</a></li>
      <li><a href="/about">About</a></li>

    </ul>

    <a href="/" aria-label="Homepage">
      <span class="mega-octicon octicon-mark-github" title="GitHub"></span>
    </a>

    <ul class="site-footer-links">
      <li>&copy; 2014 <span title="0.12719s from github-fe133-cp1-prd.iad.github.net">GitHub</span>, Inc.</li>
        <li><a href="/site/terms">Terms</a></li>
        <li><a href="/site/privacy">Privacy</a></li>
        <li><a href="/security">Security</a></li>
        <li><a href="/contact">Contact</a></li>
    </ul>
  </div><!-- /.site-footer -->
</div><!-- /.container -->


    <div class="fullscreen-overlay js-fullscreen-overlay" id="fullscreen_overlay">
  <div class="fullscreen-container js-suggester-container">
    <div class="textarea-wrap">
      <textarea name="fullscreen-contents" id="fullscreen-contents" class="fullscreen-contents js-fullscreen-contents js-suggester-field" placeholder=""></textarea>
    </div>
  </div>
  <div class="fullscreen-sidebar">
    <a href="#" class="exit-fullscreen js-exit-fullscreen tooltipped tooltipped-w" aria-label="Exit Zen Mode">
      <span class="mega-octicon octicon-screen-normal"></span>
    </a>
    <a href="#" class="theme-switcher js-theme-switcher tooltipped tooltipped-w"
      aria-label="Switch themes">
      <span class="octicon octicon-color-mode"></span>
    </a>
  </div>
</div>



    <div id="ajax-error-message" class="flash flash-error">
      <span class="octicon octicon-alert"></span>
      <a href="#" class="octicon octicon-x flash-close js-ajax-error-dismiss" aria-label="Dismiss error"></a>
      Something went wrong with that request. Please try again.
    </div>


      <script crossorigin="anonymous" src="https://assets-cdn.github.com/assets/frameworks-0c1b00f7935ae85624f5fc5d40d52d60febf92b4.js" type="text/javascript"></script>
      <script async="async" crossorigin="anonymous" src="https://assets-cdn.github.com/assets/github-cbba41b870c9e4d89d40771e5c675b37b14e9601.js" type="text/javascript"></script>
      
      
        <script async src="https://www.google-analytics.com/analytics.js"></script>
  </body>
</html>

