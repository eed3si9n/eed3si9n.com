---
title:       "sudori part 3"
type:        story
draft:       true
sticky:      false
url:         /sudori-part3
tags:        [ "sbt" ]
---

  [sudori]: https://github.com/eed3si9n/sudori
  [part1]: https://eed3si9n.com/sudori-part1
  [part2]: https://eed3si9n.com/sudori-part2
  [metaprogramming]: http://dotty.epfl.ch/docs/reference/metaprogramming/toc.html
  [Enum]: http://dotty.epfl.ch/docs/reference/enums/adts.html
  [TypeProjection]: http://dotty.epfl.ch/docs/reference/dropped-features/type-projection.html
  [so-50043630]: https://stackoverflow.com/q/50043630/3827
  [Tree]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L255
  [Transformer]: https://github.com/scala/scala/blob/v2.13.6/src/reflect/scala/reflect/api/Trees.scala#L2563
  [TreeMap]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L4370
  [Type]: http://dotty.epfl.ch/docs/reference/metaprogramming/macros.html#types-for-quotations
  [statically-unknown]: https://docs.scala-lang.org/scala3/guides/macros/faq.html#how-do-i-summon-an-expression-for-statically-unknown-types
  [Instance]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/Instance.scala
  [1c22478edc]: https://github.com/sbt/sbt-zero-thirteen/commit/1c22478edcad5b083330445317d3ef28f3fa3ef2
  [Selective]: https://eed3si9n.com/selective-functor-in-sbt
  [TypeTest]: http://dotty.epfl.ch/docs/reference/other-new-features/type-test.html
  [Lambda]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L1290
  [createFunction]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/ContextUtil.scala#L234

I'm hacking on a small project called [sudori][sudori], an experimental sbt. The initial goal is to port the macro to Scala 3. It's an exercise to take the macro apart and see if we can build it from the ground up. This an advanced area of Scala 2 and 3, and I'm finding my way around by trial and error. This is part 3.

Reference:
- [Scala 3 Reference: Metaprogramming][metaprogramming]
- [sudori part 1][part1]
- [sudori part 2][part2]



### Tuple



// sys.error(TypeRepr.of[[F1[a]] =>> (F1[Int], F1[String])].toString)


HKTypeLambda(List(F1), List(TypeBounds(TypeRef(TermRef(ThisType(TypeRef(NoPrefix,module class <root>)),object scala),Nothing),HKTypeLambda(List(a), List(TypeBounds(TypeRef(TermRef(ThisType(TypeRef(NoPrefix,module class <root>)),object scala),Nothing),TypeRef(TermRef(ThisType(TypeRef(NoPrefix,module class <root>)),object scala),Any))), TypeRef(TermRef(ThisType(TypeRef(NoPrefix,module class <root>)),object scala),Any), List()))), AppliedType(TypeRef(TermRef(ThisType(TypeRef(NoPrefix,module class <root>)),object scala),Tuple2),List(AppliedType(TypeParamRef(F1),List(TypeRef(TermRef(ThisType(TypeRef(NoPrefix,module class <root>)),object scala),Int))), AppliedType(TypeParamRef(F1),List(TypeRef(TermRef(TermRef(ThisType(TypeRef(NoPrefix,module class <root>)),object scala),Predef),String))))))

TypeLambda(
  paramNames = List("F1"),
  boundsFn = _ => List(
    TypeBounds.upper(
      TypeLambda(
        paramNames = List("a"),
        boundsFn = _ => List(TypeBounds.empty),
        bodyFn => _ => TypeRepr.of[Any],
      )
    )
  ),
  bodyFn = tl =>
    TypeRepr.of[Tuple2].appliedTo(List(
      tl.param(0).appliedTo(TypeRepr.of[Int]),
      tl.param(1).appliedTo(TypeRepr.of[String]),
    ))
)

-----


        // br.representationC.asType match
        //   case '[kx] =>
        //     typed[i.F[A1]](
        //       '{
        //         type k[x] = ${ br.representationC.asType }
        //         val _i = $instance
        //         _i
        //           .mapN[k, A1](${ br.tupleTerm.asExprOf[k[_i.F]] }, ???)
        //       }.asTerm
        //     ).asExprOf[i.F[A1]]
