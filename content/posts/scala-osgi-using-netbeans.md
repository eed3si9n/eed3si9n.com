---
title:       "Scala and OSGi using NetBeans"
type:        story
date:        2010-01-15
changed:     2010-11-05
draft:       false
promote:     true
sticky:      false
url:         /scala-osgi-using-netbeans
aliases:     [ /node/4 ]

# Summary:
# For some reason, I can't keep OSGi in my head. Everything I read about it slips away in a few weeks, and I have re-read the guides and tutorials.
# 
# Here's a memo of setting up OSGi bundle written in Scala using NetBeans, following Neil Barlett's <a href="http://neilbartlett.name/blog/osgibook/">OSGi in Practice</a>, except the book uses Eclipse.
# 

---
<!--break-->
For some reason, I can't keep OSGi in my head. Everything I read about it slips away in a few weeks, and I have re-read the guides and tutorials.

Here's a memo of setting up OSGi bundle written in Scala using NetBeans, following Neil Barlett's <a href="http://neilbartlett.name/blog/osgibook/">OSGi in Practice</a>, except the book uses Eclipse.

<h3>Installing Scala on Mac</h3>
Skip this section if you use non-Mac. Install <a href="http://www.macports.org/">MacPorts</a>. Run the following from Terminal:
<code>
sudo port install scala-devel
</code>
This could take minutes as it downloads the files.

Install <a href="http://www.rubicode.com/Software/RCEnvironment/">RCEnvironment</a> by copying <code>RCEnvironment.prefPane</code> into <code>/Library/PreferencePanes/</code>. When you open System Preferences, Environment Variables now show up. Set <code>JAVA_HOME</code> and <code>SCALA_HOME</code> to where it makes sense. I have them set to <code>/Library/Java/Home/</code> and <code>/opt/local/share/scala/</code>.

<h3>Installing NetBeans</h3>
Download <a href="http://netbeans.org/downloads/index.html">NetBeans</a>. You could pick any edition as long as it has Java SE. Follow the instructions in <a href="http://wiki.netbeans.org/Scala68v1">Scala Plugins for NetBeans 6.8 v1.x (RC1)</a> to install Scala plugin.

<h3>Installing a Framework</h3>
 <a href="http://felix.apache.org/site/downloads.cgi">Download Felix Framework binary package</a>, extract it under some location such as <code>~/Application/</code>. The felix directory will be referred to as <code>FELEX_HOME</code>.

<h3>Setting up NetBeans</h3>
Open NetBeans. Within NetBeans, open Library Manager (Tools menu → Libraries). Hit <b>New Library...</b> button, and type "ApacheFelix2.1.0" or whatever the version number you are using. Next hit <b>Add JAR/Folder...</b> button and add <code>FELIX_HOME/bin/felix.jar</code>. I've also added some source zip files under <b>Sources</b> section.

Create new Scala project by selecting (File menu → New Project...) and picking <b>Scala Application</b> under Scala folder. Enter the project name <code>OSGiTutorial</code> and accept all the other default values.  This project directory will be referred to as <code>PROJECT_HOME</code>.

Under Projects tree view, find Libraries node for the newly created project, right-click and select <b>Add Library...</b>. This should pop up a dialog where you can select ApacheFelix1.8.0 and hit <b>Add Library</b> button.

Copy <code>conf/</code> and <code>bundle/</code> from <code>FELIX_HOME</code> to <code>PROJECT_HOME</code>. If you are using Felix 2.0.1 like I am, you have to modify the <code>conf/config.properties</code> file to mimic the older behavior of Felix as follows:

Line 61:
<code>
#felix.auto.deploy.action=install,start
felix.auto.deploy.action=
</code>

Line 72:
<code>
#felix.auto.install.1=
felix.auto.start.1= \
 file:bundle/org.apache.felix.shell-1.4.1.jar \
 file:bundle/org.apache.felix.shell.tui-1.4.1.jar \
 file:bundle/org.apache.felix.bundlerepository-1.4.2.jar
</code>

<h3>Running Felix</h3>
Select (Run menu → Set Project Configuration → Customize...) to open the Project Properties. Enter <code>org.apache.felix.main.Main</code> to be the Main class, and enter
<code>-Dfelix.config.properties=file:conf/config.properties</code> to be VM options. Now, Felix will start by hitting <b>Run</b> button.

<h3>Installing bnd</h3>
Download Peter Kriens's <a href="http://www.aqute.biz/Code/Download">bnd.jar</a>, and put under some location like <code>~/Application/bnd</code>. Open Library Manager (Tools menu → Libraries). Hit <b>New Library...</b> button, and type "Bnd." Next hit <b>Add JAR/Folder...</b> button and add <code>BND_HOME/bnd-0.0.xxx.jar</code>.

Under Projects tree view, find Libraries node for the newly created project, right-click and select <b>Add Library...</b>. This should pop up a dialog where you can select Bnd and hit <b>Add Library</b> button.

<h3>Installing Scala OSGi bundle</h3>
Find out the Scala version that's being used by NetBeans by selecting (Tools menu → Scala Platforms) if you don't have <code>$SCALA_HOME</code> set, or by running 
<code>$ scala -version</code> from the Terminal if you have <code>$SCALA_HOME</code>. In my case it was 2.8.0.Beta1-RC7.

Download Heiko Seeberger's Scala OSGi bundles. The <a href="http://scala-tools.org/repo-snapshots/org/scala-lang-osgi/">snapshots</a> are available, so find OSGi bundle of scala-library for the appropriate version, and place them in some folder such as <code>~/Applications/scala-osgi</code>. Copy <code>scala-library-2.8.0-20100109.130112-12.jar</code> into <code>$PROJECT_HOME/bundle/</code> folder as well. 

<h3>Hello, World!</h3>
Under Projects tree view there should be a node for <b>Source Packages</b> and a package called <code>osgitutorial</code>. Right-click and delete <code>Main.scala</code>. Right-click, select (New → Other...) and select <b>Scala Class</b> under Scala node. Enter <code>HelloWorldActivator</code> as the name of the file and hit <b>Finish</b> button.

Here's the code for <code>HelloWorldActivator.scala</code>:
<scala>
package osgitutorial

import org.osgi.framework._

class HelloWorldActivator extends BundleActivator {
  def start(context: BundleContext) {
    println("Hello, World!");
    
    val bundleNames = context.getBundles()
      .map(b => b.getSymbolicName())
      .filter(b => b != context.getBundle());
    println("Installed bundles: " + bundleNames.mkString(", "));
  }

  def stop(context: BundleContext) {
    println("Goodbye, World!");
  }
}
</scala>

Switch to Files tree view next Project tree view on NetBeans. Create <code>helloworld.bnd</code> by selecting (File menu → New File...), and selecting <b>Empty File</b> under <b>Other</b>. Click <b>Next</b>, type <code>helloworld.bnd</code> into the file name, and click <b>Finish</b>. Here's the content for <code>helloworld.bnd</code>:

<code>
# helloworld.bnd

Private-Package: osgitutorial
Bundle-Activator: osgitutorial.HelloWorldActivator
</code>

Under Files tree view, open build.xml. This is an Ant build file. Add two targets within the project tags as follows:

<code>

<?xml version="1.0" encoding="UTF-8"?>
<project name="OSGi_Tutorial" default="default" basedir=".">
    <description>Builds, tests, and runs the project OSGi Tutorial.</description>
    <import file="nbproject/build-impl.xml"/>
    <target name="bnd-build">
        <taskdef name="bnd"
          classname="aQute.bnd.ant.BndTask"
          classpath="dist/lib/bnd-0.0.337.jar"/>

        <bnd
          classpath="build/classes"
          eclipse="false"
          failok="false"
          exceptions="true"
          files="helloworld.bnd"
          output="bundle"/>
    </target>

    <target name="-post-jar" depends="bnd-build">
    </target>
</project>
</code>

Now by clicking <b>Build</b> button on NetBeans, OSGi bundle helloworld.jar gets created under <code>bundle/</code> folder.

<h3>Installing the bundles</h3>
If you haven't already, hit <b>Run</b> button on NetBeans to start Felix. It should look like the following:

<code>
init:
deps-jar:
compile:
run:

Welcome to Felix.
=================

->
</code>

This is Felix shell, which we could use to install bundles. Type <code>ps</code> at the prompt and hit return. This will display all active bundles:

<code>
-> ps
START LEVEL 1
   ID   State         Level  Name
[   0] [Active     ] [    0] System Bundle (2.0.1)
[   1] [Active     ] [    1] Apache Felix Shell Service (1.4.1)
[   2] [Active     ] [    1] Apache Felix Shell TUI (1.4.1)
[   3] [Active     ] [    1] Apache Felix Bundle Repository (1.4.2)
-> 
</code>

Now type the following command at Felix shell:
<code>install file:bundle/helloworld.jar</code>
This should return
<code>-> install file:bundle/helloworld.jar
Bundle ID: 4</code>

Next, type following command at Felix shell:
<code>start 4</code>
This should return
<code>-> start 4
org.osgi.framework.BundleException: Unresolved constraint in bundle 4: package; (package=scala.runtime)
</code>

So helloworld bundle is loaded into Felix, but it's not able to resolve <code>scala.runtime</code> package, which makes sense since we haven't load it yet.

Now type the following command at Felix shell:
<code>install file:bundle/scala-library-2.8.0-20100109.130112-12.jar</code>
This should return
<code>-> install file:bundle/scala-library-2.8.0-20100109.130112-12.jar
Bundle ID: 5</code>

Next type <code>start 4</code> again at Felix shell. This should return
<code>-> start 4
Hello, World!
Installed bundles: org.apache.felix.framework, org.apache.felix.shell, org.apache.felix.shell.tui, org.apache.felix.bundlerepository, helloworld, org.scala-lang-osgi.scala-library
</code>

<h3>Incremental Development</h3>
Now that both <b>Build</b> button and <b>Run</b> button are configured, we can try incremental development by updating bundles without shutting down the OSGi container.

Make some changes in <code>HelloWorldActivator.scala</code>. For example, change "Hello, World!" to "Bonjour le Monde!" Then, hit the <b>Build</b> button to build <code>helloworld.jar</code> bundle.

Change the Output tab back to <b>OSGi_Tutorial (run)</b> and type <code>stop 4</code> at Felix shell. This stops the bundle. Next type <code>update 4</code> at Felix shell. This updates the bundle. Finally by typing <code>start 4</code> at the shell, we can start the bundle again:
<code>-> stop 4
Goodbye, World!
-> update 4
-> start 4
Bonjour le Monde!
Installed bundles: org.apache.felix.framework, org.apache.felix.shell, org.apache.felix.shell.tui, org.apache.felix.bundlerepository, helloworld, org.scala-lang-osgi.scala-library
</code>

<h3>In the end</h3>
Type <code>shutdown</code> to shutdown Felix. The installed bundles will stay even after the shutdown. To clear the state, you have to purge <code>PROJECT_HOME/felix-cache/</code> folder. I merely followed along Neil Barlett's <a href="http://neilbartlett.name/blog/osgibook/">OSGi in Practice</a>, so most of the credits should go to him.
