## register your nick

    /msg NickServ REGISTER %password% youremail@example.com

[What is the recommended way to set up my IRC nickname?](http://freenode.net/faq.shtml#nicksetup)

## make new channel

To check whether a channel has already been registered, use the command:

    /msg ChanServ info ##channelname

    /join ##channelname

The command to register your channel (once you’ve joined it and you have op status) is as follows:

    /msg ChanServ register ##channelname

[Registering a channel on freenode](http://blog.freenode.net/2008/04/registering-a-channel-on-freenode/)

## moderate a channel

Only users who have a voice are able to talk.

    /mode ##channelname +m

[Using the Network](https://freenode.net/using_the_network.shtml)

## give voice

For freenode,

    /msg ChanServ FLAGS ##channelname Jon +v

The standard way seems to be `/mode ##channelname +v Jon`.

Here's removing the voice

    /msg ChanServ FLAGS ##channelname Jon -v

## give operator rights

For freenode,

    /msg ChanServ FLAGS ##channelname Jon +oO

The standard way seems to be `/mode ##channelname +o Jon`.
