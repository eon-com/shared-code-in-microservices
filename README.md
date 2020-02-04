# Shared Code in Microservices? Domain Driven Design to the Rescue


Microservices have been around for a while so they are state-of-the-art rather than just a hype. Countless blog articles, books, best practices, tweets and war stories from concrete projects testify to a living architectural style. There is hardly a question that has not been repeatedly examined from all sides: starting with the basic concept and the technical layout, to topics such as team and communication structure, deployment, service discovery, logging and monitoring, there are enough instructions, frameworks, tools, and literature. Therefore this article is not intended as another comprehensive introduction to microservices.

This blog post is rather about a topic that comes up again and again and that concerns conference pundits as well as developers in the verbal fights in the coffee kitchen: Is it reasonable to reuse code in microservice projects? Is shared code, in whatever form, a brutal violation of the isolation principle? Or does **Don't Repeat Yourself** (DRY-principle) also apply here? After briefly touching upon the principle of loose coupling and isolation we will discuss the traditional promise of reusability, its flipside, and the meaning of **Bounded Context** in the realm of **Domain-Driven Design*** (DDD). Afterwards we will delve into examples where it is perfectly legitimate to share code in microservices including some edge cases and how to deal with them. Finally we will discuss shared **Infrastructure as Code**.

## Loose Coupling and Isolation

Microservices should not be an end in themselves. One of the core goals in the introduction of microservices is decoupling of components that are designed and implemented under technological autonomy, communicating via interfaces. The purpose is to manage complexity in an effective way, to provide a higher degree of isolation during the application runtime and the to test business ideas and technologies faster (and to throw them away if they prove to be unsuitable).

A microservice typically implements the business process of a specialist domain, it maintains and changes its own locally valid data, it is responsible for its management and exposes explicit interfaces. So it is "reasonably small" and focuses on a specific task. This strict modularization concept and the division of the teams into domain components result in several other advantages [1][2].

But even in microservice projects, there is often a desire for shared use of database schemas, data sources, code for access to frequently used objects in a domain or existing functionality. There are two forces working in different directions at one point: the “maximum generic reusability” on the one hand, the concept of independence and isolation on the other.

## Reusability as the Promise of Salvation?

The strong desire for reusability is not surprising as the DRY-principle has been the mantra of software development for decades. And even today developers are being instilled, redundancy is the worst of all developer villains, after all it would make more sense to "inherit" code instead of writing. What can be reused does not have to be rewritten and thus reduces costs. Reusable code should ideally meet the following requirements:

* Must fit in many cases
* High quality
* Good documentation 

Developers commonly argue that the disclosure of such code in an open source project automatically fulfills the requirements described above as external contributions and bug reports lead to an improvement in the code. Publication as an open source library actually makes sense, after all, you don't want to use code that you wouldn't be willing to distribute to external users. But even if it makes it more difficult for things that are too specific to infiltrate into such a shared project, one crucial question remains unanswered: Where exactly is the boundary between sensible code sharing and excessive generalization?

Answers to this are provided by the concept of **Bounded Context** from **DDD**, an approach to software modeling that focuses very strongly on the business of an application domain.

## Bounded Context!

The urge to generalize everything has led to global data models and wrong technical abstraction in many past projects. Instead of promised productivity boosts, this procedure slows down the development process. The reason for this is obvious: A technically incorrect generalization leads to a high coordination effort, since many developers involved have to coordinate with each other. Finally, it has to be decided which code ends up in a shared component and how its quality is ensured. In extreme cases you end up with an entire organization that is dedicated to “cross-sectional tasks” as guardian of the holy grail of reusability which is not customer facing and slows down delivery of software [3].

In contrast, the concept of bounded context is central to DDD. Each domain usually consists of several bounded contexts. Such a “context boundary” describes the scope of a technical model.

Let's give a simple example: The term **flight** from the aviation industry has several specific meanings, depending on the context. From a passenger's perspective, a flight is the transportation of people to a destination airport, either in the form of a direct flight or with a stopover. From the point of view of the on-board personnel, a flight consists of take-off and landing. And airport maintenance technicians look at a flight from the position of aircraft maintenance. Depending on the context, this term means something different.

![Image displaying concept of a flight from perspective of different businesses](./images/flight.png)

Modeling a flight in the form of a generic flight class would only lead to confusion. Individual cases should be modeled in their own bounded contexts. Attempting to outsource similarities and common features to a parent class and to implement individual characteristics in child classes inevitably leads to strong coupling [4].

A rule of thumb:

* Duplication is better than false abstraction
* Redundancies should be consciously accepted if the alternative is a strong coupling
* No reuse of business logic across multiple bounded contexts 

Code reuse for code within a bounded context, however, is not critical.

## Cross-cutting Concerns

What about libraries like Apache Commons or Google Guava? Should I avoid using them to stick with true microservices doctrine? Of course not! Shared libraries for technical issues such as logging, monitoring, tracing, string manipulation, collections or abstraction layers for infrastructure access are cross-cutting concerns, as they do not depend on the context of a domain. It is perfectly okay to share libraries that involve non-technical aspects [5].

### Dependency Hell

However, this answer does not address the problem that such libraries often have the disadvantage of many transitive dependencies. It is only a matter of time before you catch version conflicts and it is not uncommon to end up in the notorious **Dependency Hell**.

One way to avoid the dependency hell problem is to provide very lean libraries for clearly defined tasks with little or no dependency. Such libraries are in stark contrast to general-purpose libraries.

### Deployment Dependencies

The following scenario, which originates from a real project, is somewhat more complex: A library for health checks verifies, among other things, the connection to Elasticsearch and the existence of certain indices and aliases. Under the hood, this library uses an open source library that provides an Elasticsearch client. In the context of a user story, new features have been added to the health check library. At the same time there was an upgrade to a new major version [6] of the Elasticsearch client which led to a significant extra effort.

![Image displaying dependency version conflicts](./images/deps.png)

But how? In our specific example, services that use the new health checks also use the same Elasticsearch client in their own (technical) code, only in an older version. The increased effort was due to adjustments in the concerned services. To avoid such a situation there are two possible solutions:

* Replacement of the Elasticsearch client in the health checks with a lightweight solution (checking the connection etc. does not need all the features of a comprehensive Elasticsearch client)
* (Temporary) provision of the Health Check Library in two versions: one with the old and one with the new version of the Elasticsearch client 

At first glance, both approaches seem like unnecessary trouble. However, with several dozen services, this effort prevents extensive "forced upgrades", the inclusion of the new health checks can be done gradually service by service.

### Shared Service

The following scenario goes in a similar direction: Assume that a shared library is provided for the use of a central service. If changes are made to this service, all microservices would have to use an updated version of this library. If the services in question are managed by different teams, this entails a considerable coordination effort in redeployment.

Backward-compatible changes to the service, on the other hand, do not result in deployment dependencies, since older versions of this library are still functional. Temporary provision of two different versions of the service including two different library versions is also a conceivable solution. The older variant is then switched off as soon as it is ensured that no client is dependent on it anymore.

Generally speaking, in the case of external dependencies in a microservice, the freedom of choice of the specific version of a library used should always be ensured in order to avoid dependencies of this kind.

## DDD Context Maps and Shared Kernel

In DDD every bounded context has its own **Ubiqituous Language** [7]. One of the features of DDD is **Context Maps**, which allows grasping the different relationships and translations between bounded contexts, their models and team-wide languages. To explain all kinds of context maps would go beyond the scope of the discussion, so we limit ourselves to a use case in which areas of the domain model are shared between different teams and hence different bounded contexts: **Shared Kernel**. Sometimes it's valid that two teams share common structures; this applies in particular if they are subject to frequent changes. Instead of multiple implementations with inconsistencies a small part of the data model (intersection of two bounded contexts) can be shared between different teams.

Of course, this procedure contradicts the principles of loose coupling and isolation mentioned above, because the independence between microservices is lost. This procedure is a trade-off and needs to be weighed up in line with usage. **It should not be used as a justification for a universal data model in a complex application landscape!** Nevertheless, there are scenarios such as session or authentication logic, where such a procedure is appropriate.

A shared kernel is often difficult to create and to maintain, because you have to achieve open communication between the teams and permanent agreement on what belongs to the shared model. It requires a healthy communication culture between the teams involved.

## Shared Infrastructure as Code

For the sake of an healthy and productive team autonomy and to avoid infrastructure monoliths, it is recommended to divide **Infrastructure as Code** artifacts according to macroarchitecture and microarchitecture aspects. All infrastructure definitions that belong directly to a certain domain/bounded context should be part of the respective microservice. Let's give an example to illustrate this: A microservice that installs data and then stores it in a message queue should include the infrastructure definition of the topic of the message queue. The subscriptions of the queue, on the other hand, should be defined in services, which consume data from this topic.

All infrastructure definitions that cannot be clearly assigned to a certain service are aspirants for the macro infrastructure (or macro stack). So this stack contains all cross-cutting aspects and ideally consists exclusively of definitions which rarely change. This typically includes network and security infrastructure [8]. The division into various service stacks (micro-stacks) and macro-stacks can be implemented, for example, using the modularization and inclusion concepts of Terraform and CloudFormationn [9].

## Summary

Shared code or code reuse in microservices leads to dependencies, which can lead the core idea of ​​this architecture style to absurdity. Therefore, one should orientate oneself on the idea of ​​the bounded context of domain driven design and differentiate between technical and non-technical aspects. The latter can be converted into shared code. However, it is recommended to keep it lean and to ensure that it is backwards compatible when changes are made to avoid deployment dependencies. The **Shared Kernel** pattern should be used with care and also requires a healthy communication culture between the teams. Infrastructure as code is to be assessed from a similar point of view as program code.

---

[1] See also http://www.informit.com/articles/article.aspx?p=2738465&seqNum=2  
[2] Major benefits of microservices:

* Independent release and deployment of the services (while maintaining backward compatibility of interfaces)
* Separate life cycles
* Scaling according to needs
* Greater technological independence, since ideally there are no direct dependencies on other microservices
* Fast local decisions on technical and micro-architectural questions by autonomous teams
* Less coordination effort between the different teams
* Freedom of choice of technology (languages, frameworks), thereby greater team commitment (however, this freedom of choice is often restricted in practice in order to avoid a technology zoo)

[3] See also https://medium.com/ingeniouslysimple/context-mapping-in-domain-driven-design-9063465d2eb8
[4] In addition, the flexibility achieved when focusing on reusability also leads to an increase in complexity. One also speaks of the use / reuse paradox: http://techdistrict.kirkk.com/2009/10/07/the-usereuse-paradox/.   
[5] The statement applies not only to microservices projects, but generally wherever you want to modularize sensibly. In addition, changes to the base class will quickly violate the Liskov substitution principle: http://newsight.de/2015/01/07/das-liskov-substitution-principle.  
[6] We limit ourselves to Java in this scenario, but the statements made here also apply to other languages.  
[7] See https://martinfowler.com/bliki/UbiquitousLanguage.html   
[8] Semantic versioning: https://semver.org/ 
[9] See https://www.infoq.com/news/2018/06/cloud-native-continuous-delivery 