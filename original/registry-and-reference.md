  [fowler]: http://martinfowler.com/eaaCatalog/registry.html

There's a "pattern" that I've been thinking about, which arises in some situation while persisting/serializing objects.

To motivate this, consider the following case class:

<scala>
scala> case class User(name: String, parents: List[User])
defined class User

scala> val alice = User("Alice", Nil)
alice: User = User(Alice,List())

scala> val bob = User("Bob", alice :: Nil)
bob: User = User(Bob,List(User(Alice,List())))

scala> val charles = User("Charles", bob :: Nil)
charles: User = User(Charles,List(User(Bob,List(User(Alice,List())))))

scala> val users = List(alice, bob, charles)
users: List[User] = List(User(Alice,List()), User(Bob,List(User(Alice,List()))),
  User(Charles,List(User(Bob,List(User(Alice,List()))))))
</scala>

The important part is that it contains `parents` field, which contains a list of other users.
Now let's say you want to turn `users` list of users into JSON.

<code>
[{ "name": "Alice", "parents": [] },
{ "name": "Bob",
  "parents": [{ "name": "Alice", "parents": [] }] },
{ "name": "Charles",
  "parents": [{ "name": "Bob", "parents": [{ "name": "Alice", "parents": [] }] }] }]
</code>

There are mutiple issues with this approach. First, the JSON representation is inefficient and not natural way you'd expect JSON data to look like. Second, when we bring this back to the case class we will have to instantiate the entire graph of objects, which again is inefficient and a lot of times undesirable.

This becomes more tricky if the data contains something like function values.

### registry and reference pattern

The workaround I've been thinking about is registry and reference pattern. The idea is that you would register all three users beforehand into a "registry", and on JSON you'd transmit something like this:

<code>
["Alice", "Bob", "Charles"]
</code>

I Googled for it, and apparently Martin Fowler has named it [Registry pattern][fowler] too. In his model, Registry contains two methods:

- getPerson(id)
- addPerson(Person)

What I want to do is come up with a data structure that works for an arbitrary pair of datatype and its reference.

### usage

Before getting into the implementation, let's look at how this will be used.

<scala>
scala> case class UserRef(name: String)
defined class UserRef
</scala>

You first have to define an appropriate reference type for `User`. This would the addressing system for your value such as ids, and URLs.

<scala>
scala> implicit val userReg = Registerable[User, UserRef](u => UserRef(u.name))
userReg: sbt.Registerable.Aux[User,UserRef] = sbt.Registerable$$anon$1@69154910
</scala>

Next you have to tell how one can create `UserRef` from a user.

<scala>
scala> val aliceRef: UserRef = Registry[User].append(alice)
aliceRef: UserRef = UserRef(Alice)
</scala>

When you append `alice` to `Registry[User]`, it returns a reference to Alice.

<scala>
scala> val bobRef: UserRef = Registry[User].append(bob)
bobRef: UserRef = UserRef(Bob)

scala> val charlesRef: UserRef = Registry[User].append(charles)
charlesRef: UserRef = UserRef(Charles)

scala> val xs = List(aliceRef, bobRef, charlesRef)
xs: List[UserRef] = List(UserRef(Alice), UserRef(Bob), UserRef(Charles))
</scala>

We will be using `UserRef` in place of actual `User`. To express a list of users, we can now use `List[UserRef]`. `xs` can then be persisted as `["Alice", "Bob", "Charles"]`.

We often care about the references to the values, not how the value itself is constructed. For example, the list could represent a list of users living within 30 miles from the city center, etc. We only need to know their identities.

Another way of looking at this, is that we are trying to provide a form of indirection. As I mentioned above, URL is a good example of that.

If you need to turn the reference into the actual `User`s, you can look them up from the registry:

<scala>
scala> val users = xs map { x => Registry[User].get(x).get }
users: List[User] = List(User(Alice,List()), User(Bob,List(User(Alice,List()))), User(Charles,List(User(Bob,List(User(Alice,List()))))))
</scala>

Note that `Registry` acts as a `Map` and it will only accept the reference type for the given datatype. If you pass in an `Int` by mistake, it will be caught during compilation.

<scala>
scala> val bad = Registry[User].get(0)
<console>:15: error: inferred type arguments [Int] do not conform to method get's type parameter bounds [B <: userReg.R]
       val bad = Registry[User].get(0)
                                ^
<console>:15: error: type mismatch;
 found   : Int(0)
 required: B
       val bad = Registry[User].get(0)
                                    ^
</scala>

### implemetation

There are two parts the implementation. First is the `Registerable`:

<scala>
trait Registerable[A] {
  type R
  def toRef(a: A): R
}

object Registerable {
  type Aux[A0, R0] = Registerable[A0] {
    type R = R0
  }
  def apply[A, R0](toRef0: A => R0): Aux[A, R0] = new Registerable[A] {
    type R = R0
    def toRef(a: A): R = toRef0(a)
  }
}
</scala>

Since we need the datatype `A` and the reference type `R`, the typeclass instance takes two type parameters.
But at the same time we want to look up this instance only using `A`. To achieve this we can use `Aux` type, which is a technique popularized by Miles Sabin's shapeless.

Next part is `Registry`, which is a mutable concurrent TrieMap wrapper.

<scala>
import scala.collection.concurrent.TrieMap

object Registry {
  private val registries: TrieMap[Registerable[_], Registry[_, _]] = TrieMap.empty
  def apply[A](implicit ev: Registerable[A]): Registry[A, ev.R] =
    registries.getOrElseUpdate(ev, new Registry[A, ev.R](ev)).
      asInstanceOf[Registry[A, ev.R]]
}

class Registry[A, R](ev: Registerable.Aux[A, R]) {
  private val registered: TrieMap[R, A] = TrieMap.empty
  def get[B <: R](ref: B): Option[A] =
    registered.get(ref)

  def append(value: A): R = {
    val key = ev.toRef(value)
    if (!registered.contains(key)) {
      registered(key) = value
    }
    key
  }
}
</scala>

The only notable bit is `def get`, which accepts a type parameter `B` with a constraint `B <: R`.
We can also use `B =:= R` as an implicit proof, but `B <: R` would allow subtypes of `R` as a key as well.

Note that this keeps all the values in memory, so it's not intended to append tons of values.

### isn't this a global object?

One caveat is that this registry pattern is essentially a glorified global object.
It's not necessary to make the registry global, but there's some notion of timing involved here:

1. You append all used values into the registry.
2. You can use the references to persist the values into JSON etc.

On the other end of the wire, you have to repeat the same thing.

1. Somehow figure out all the used values and append them all into the registry.
2. Recover the references from JSON etc.
3. Convert the references into values.

When there's interleaving of appending and using the references it might get into more complicated situation.

Even though global object is not ideal, I think it's helpful in a situation where you need to persist something that is difficult to persist. A good example of that is a function value such as `String => String`. Within sbt's internal implementation, some things are expressed as wrapper around function values for flexibility. These are difficult to persist and nor is it necessary to persist the actual functions.

See `ModuleID` for example. This is a frequently occuring datatype that the build user will define.

<scala>
final case class ModuleID(organization: String, name: String, revision: String,
  configurations: Option[String] = None, ....
  crossVersion: CrossVersion = CrossVersion.Disabled)
</scala>

One of the fields on `ModuleID` is of type `CrossVersion`. This is a sealed trait whose children includes a function wrapper called `Binary`:

<scala>
  final class Binary(val remapVersion: String => String) extends CrossVersion {
    override def toString = "Binary"
  }
</scala>

If we agree that we can't persist  `String => String`, then basically `ModuleID` and the entire dependency graph are not possible to persist. To persist the dependency graph, sbt 0.13 currently throws out the function value when it persists the dependency graph into JSON, and uses the default value, which is the identity function. (This should be ok since the persisted `ModuleID` only appears in `UpdateReport`, and not used during the actual dependency resolution.)

By using the registry and reference pattern, we can, for example, define `CrossVersionRef` with a `String` name and force the build user to name the logic when they deviate from the predefined values. If `CrossVersionRef` were used in `ModuleID`, it would get us closer to being able to safely persist them into JSON.

### equality

A related topic is equality check. A persistable reference value is easy to check for equality.

### summary

There are situations where we want to persist something that contains an internal structure or a function that are difficult to persist.
The registry and reference pattern offers a workaround to this situation, albeit it does introduce initialization complexity.

`Registry` is an implementation of a registry that uses `TrieMap` internally, and uses typeclass to determine the reference type given a value type `A`.
