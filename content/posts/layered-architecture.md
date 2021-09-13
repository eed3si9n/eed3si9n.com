---
title:       "Layered Architecture"
type:        story
date:        2009-12-07
changed:     2010-11-05
draft:       false
promote:     true
sticky:      false
url:         /layered-architecture
aliases:     [ /node/5 ]
---
One of my favorites from msdn is <a href="http://msdn.microsoft.com/en-us/library/ee817664.aspx">Application Architecture for .NET: Designing Applications and Services</a> by <a href="http://edjez.instedd.org/">Eduardo Jezierski</a>. The version 2.0 is <a href="http://msdn.microsoft.com/en-us/library/dd673617.aspx">Microsoft Application Architecture Guide</a> by <a href="http://blogs.msdn.com/jmeier/">J.D. Meier</a> et al, but it's much more beefier than the original. Currently 1.0 is put under Retired node in msdn.

<!--more-->
<!--break-->
Application Architecture 1.0 focuses on Layered Architecture, which could be summarized as the following diagram:
<img src="http://eed3si9n.com/images/f00aa01.gif" />

The architecture doesn't solve all the problems, but the idea of introducing data access layer (DAL), creating service interface on top of business logic layer (BLL), and topping it with presentation layer was refreshing at the time, and still remain relevant. The separation of concerns, especially of UI and business logic has been around a while. A notable example is that of <a href="http://msdn.microsoft.com/en-us/library/ms978748.aspx">Model-View-Controller (MVC) pattern</a>, but that's where the similarity ends:
<cite>The Model-View-Controller (MVC) pattern separates the modeling of the domain, the presentation, and the actions based on user input into three separate classes [Burbeck92]</cite >

Coming from Xerox PARC in 1979, MVC is more of a desktop application idiom than an architecture pattern. The Model class encapsulates entirety of business logic, data, and its persistence. There's really no concern for scalability or communication across the wire type of thing. The goal is to separate out purity of business domain model from the earthiness of UI. The term MVC however seems to have been misused in recent years, especially when used in the context of web frameworks like rails.

Layered Architecture on the other hand slices Model component into many pieces. .NET Pet Shop was one of examples at the time the article came around. Inspired by the J2EE counterpart, it adopted <a href="http://msdn.microsoft.com/en-us/library/ms978717.aspx">Data Transfer Object pattern</a> instead of DataSet. In the .NET lingo, Data Transfer Objects (DTO) are called Business entity components or Business Entities. This is subtle point that the term includes the word <i>component</i>. In object-oriented (OO) way, creating a class that is devoid of logic goes completely against the central dogma; however, in <a href="http://en.wikipedia.org/wiki/Component-based_software_engineering">component-based software engineering (CBSE)</a>, DTO can coexist with everything else perfectly fine. Ironically the term OOP also came from Xerox PARC with Smalltalk. There's no argument that OO has brought great things, but much of the recent concerns such as modularity, encapsulation, reusability, and substitutability goes beyond mapping human concepts onto code. Component-based way bridges the gap between these engineering concerns and what the term OO can hold reasonably.  

What DTO buys is the independence within and outside of the codebase. For example, if DTO contained nothing but data, it could be represented as XML document or JSON object, which then could be transmitted over the wire. It could also be data persistence into SQL Server or Oracle, as I remember .NET Pet Shop 2 provided two implementations of DAL. In general, by separating out predictable <i>methods</i> from the class, DTO can outlive a purpose like saving itself into database or displaying itself and be reusable. If one extends this to n processors, it becomes <a href="http://java.sun.com/blueprints/corej2eepatterns/Patterns/InterceptingFilter.html">Intercepting Filter pattern</a> although its application is usually limited.

In the Application Architecture Guide 2.0, Microsoft has gone back to the MVC type definition of Business Entity components:
<cite>Business entities, or—more generally—business objects, encapsulate the business logic and data necessary to represent real world elements, such as Customers or Orders, within your application. They store data values and expose them through properties; contain and manage business data used by the application; and provide stateful programmatic access to the business data and related functionality. Business entities also validate the data contained within the entity and encapsulate business logic to ensure consistency and to implement business rules and behavior.</cite>

Here, business entities are elevated to <i>smarter</i> business object with business logic and validation. <a href="http://msdn.microsoft.com/en-us/library/ee658106.aspx">Chapter 13 Designing Business Entities</a> goes into details of choosing between custom business object, DataSet, and XML. One of the things that has become more common since the old days is the object/relational mapping (O/R mapping) and related persistence technology like Hibernate and Entity Framework. These technology can certainly push DAL forward, but it could contaminate either the database design or the class design by forcing them together too much.
