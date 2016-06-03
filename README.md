# hubot-skeddly

Skeddly integration for listing, starting, and stopping Skeddly actions.

## Installation

1. In the hubot directory, run:

```
npm install hubot-skeddly --save
```

2. Add **hubot-skeddly** to your `external-scripts.json` file:

```
["hubot-skeddly"]
```

## Configuration

The following environment variables are required for configuration:

* HUBOT_SKEDDLY_API_KEY - Your Skeddly API key

## Samples

### List all actions

```
you> hubot list actions
hubot> The current list of Skeddly actions are:
        Backup Development Servers (<action-id>)
        Start Development Servers (<action-id>)
```

### List running actions

```
you> hubot list running actions
hubot> These are the running Skeddly actions:
        Action 'Start Development Servers' is running. It started Today at 8:00 AM.
         Link: https://app.skeddly.com/Activity/Log/<action-id>
```

### Start an action

```
you> hubot start action Start Development Servers
hubot> Starting 1 action(s)
       Action 'Start Development Servers' (<action-id>) started
```

### Stop a running action

```
you> hubot stop action Start Development Servers
hubot> Action execution <action-id> was stopped.
```

## Credits

This script was heavily influenced by:

* [hubot-pager-me](https://github.com/hubot-scripts/hubot-pager-me)
* [hubot-pagerduty-github](https://github.com/hubot-scripts/hubot-pagerduty-github)

