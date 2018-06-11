module EllipticalArc2d
    exposing
        ( ArcLengthParameterized
        , EllipticalArc2d
        , arcLength
        , arcLengthParameterization
        , arcLengthParameterized
        , axes
        , centerPoint
        , endPoint
        , firstDerivative
        , firstDerivativesAt
        , fromEndpoints
        , maxSecondDerivativeMagnitude
        , mirrorAcross
        , placeIn
        , pointAlong
        , pointOn
        , pointsAt
        , relativeTo
        , reverse
        , rotateAround
        , sampleAlong
        , sampler
        , samplesAt
        , scaleAbout
        , startAngle
        , startPoint
        , sweptAngle
        , translateBy
        , translateIn
        , underlyingArc
        , with
        , xAxis
        , xDirection
        , xRadius
        , yAxis
        , yDirection
        , yRadius
        )

{-| <img src="https://ianmackenzie.github.io/elm-geometry/1.0.0/EllipticalArc2d/icon.svg" alt="EllipticalArc2d" width="160">

An `EllipticalArc2d` is a section of an `Ellipse2d` with a start and end point.
This module includes functionality for

  - Constructing an elliptical arc from its center or end points
  - Scaling, rotating, translating and mirroring elliptical arcs
  - Evaluating points and derivative vectors along elliptical arcs
  - Forming arc length parameterizations of elliptical arcs

The `startAngle` and `sweptAngle` values referred to below are not actually
proper angles but instead refer to values of the [ellipse parameter](https://en.wikipedia.org/wiki/Ellipse#Parametric_representation).
However, in simple cases you don't need to worry about the difference - if
`startAngle` and `sweptAngle` are both multiples of 90 degrees, then you can
treat them as actual angles and everything will behave as you expect.

@docs EllipticalArc2d


# Constructors

@docs with, fromEndpoints


# Properties

@docs startAngle, sweptAngle, startPoint, endPoint

All remaining properties of elliptical arcs are actually just properties of the
underlying ellipse; check out the [Ellipse2d](OpenSolid-Ellipse2d) module for
details.

@docs centerPoint, axes, xAxis, yAxis, xDirection, yDirection, xRadius, yRadius


# Evaluation

@docs pointOn, pointsAt, sampler, samplesAt


# Transformations

@docs reverse, scaleAbout, rotateAround, translateBy, translateIn, mirrorAcross


# Coordinate conversions

@docs relativeTo, placeIn


# Arc length parameterization

@docs ArcLengthParameterized, arcLengthParameterized, arcLength, pointAlong, sampleAlong


## Low level

An `ArcLengthParameterized` value is a combination of an
[`ArcLengthParameterization`](Geometry-ArcLengthParameterization) and an
underlying `EllipticalArc2d`. If you need to do something fancy, you can extract
these two values separately.

@docs arcLengthParameterization, underlyingArc


# Differentiation

You are unlikely to need to use these functions directly, but they are useful if
you are writing low-level geometric algorithms.

@docs firstDerivative, firstDerivativesAt, maxSecondDerivativeMagnitude

-}

import Axis2d exposing (Axis2d)
import Curve.ArcLengthParameterization as ArcLengthParameterization exposing (ArcLengthParameterization)
import Direction2d exposing (Direction2d)
import Ellipse2d exposing (Ellipse2d)
import Frame2d exposing (Frame2d)
import Geometry.ParameterValue as ParameterValue exposing (ParameterValue)
import Geometry.SweptAngle as SweptAngle exposing (SweptAngle)
import Geometry.Types as Types
import Interval
import Point2d exposing (Point2d)
import Vector2d exposing (Vector2d)


{-| An elliptical arc in 2D.
-}
type alias EllipticalArc2d =
    Types.EllipticalArc2d


{-| Construct an elliptical arc from its center point, X direction, X and Y
radii, start angle and swept angle. Any negative sign on `xRadius` or `yRadius`
will be ignored (the absolute values will be used).

For example, to construct a simple 90 degree elliptical arc, you might use

    exampleArc =
        EllipticalArc2d.with
            { centerPoint = Point2d.origin
            , xDirection = Direction2d.x
            , xRadius = 2
            , yRadius = 1
            , startAngle = 0
            , sweptAngle = degrees 90
            }

![90 degree elliptical arc](https://ianmackenzie.github.io/elm-geometry/1.0.0/EllipticalArc2d/with1.svg)

To make an inclined 180 degree elliptical arc, you might use

    EllipticalArc2d.with
        { centerPoint = Point2d.origin
        , xDirection = Direction2d.fromAngle (degrees 30)
        , xRadius = 2
        , yRadius = 1
        , startAngle = degrees -90
        , sweptAngle = degrees 180
        }

![180 degree inclined elliptical arc](https://ianmackenzie.github.io/elm-geometry/1.0.0/EllipticalArc2d/with2.svg)

-}
with : { centerPoint : Point2d, xDirection : Direction2d, xRadius : Float, yRadius : Float, startAngle : Float, sweptAngle : Float } -> EllipticalArc2d
with properties =
    Types.EllipticalArc2d
        { ellipse =
            Ellipse2d.with
                { centerPoint = properties.centerPoint
                , xDirection = properties.xDirection
                , xRadius = properties.xRadius
                , yRadius = properties.yRadius
                }
        , startAngle = properties.startAngle
        , sweptAngle = properties.sweptAngle
        }


{-| Attempt to construct an elliptical arc from its endpoints, X direction, and
X and Y radii. For any given valid set of these inputs, there are four possible
solutions, so you also need to specify which of the four solutions you want -
whether the swept angle of the arc should be less than or greater than 180
degrees, and whether the swept angle should be positive (counterclockwise) or
negative (clockwise).

The example below is interactive; try dragging either endpoint or the tip of the
X direction (or the center point to move the whole arc), clicking on the X or Y
radial lines and then scrolling to changet that radius, or clicking/tapping on
the various dashed arcs to switch what kind of swept angle to use.

<iframe src="https://ianmackenzie.github.io/elm-geometry/1.0.0/EllipticalArc2d/fromEndpoints.html" style="width: 500px; height: 400px" scrolling=no frameborder=0>
`https://ianmackenzie.github.io/elm-geometry/1.0.0/EllipticalArc2d/fromEndpoints.html`
</iframe>

This function will return `Nothing` if no solution can found. Typically this
means that the two endpoints are too far apart, but could also mean that one of
the specified radii was negative or zero, or the two given points were
coincident.

The behavior of this function is very close to [the SVG spec](https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes),
but when 'out of range' parameters are given this function will simply return
`Nothing` instead of attempting to degrade gracefully (for example, by
increasing X and Y radius slightly if the given endpoints are slightly too far
apart). Note that this means this function is dangerous to use for 180 degree
arcs, since then slight numerical roundoff can mean the difference between a
solution being found and not - for 180 degree arcs it is safer to use
`EllipticalArc2d.with` instead.

-}
fromEndpoints : { startPoint : Point2d, endPoint : Point2d, xRadius : Float, yRadius : Float, xDirection : Direction2d, sweptAngle : SweptAngle } -> Maybe EllipticalArc2d
fromEndpoints arguments =
    if arguments.xRadius > 0 && arguments.yRadius > 0 then
        let
            temporaryFrame =
                Frame2d.withXDirection arguments.xDirection
                    (arguments.startPoint
                        |> Point2d.translateIn arguments.xDirection
                            -arguments.xRadius
                    )

            ( x2Ellipse, y2Ellipse ) =
                arguments.endPoint
                    |> Point2d.relativeTo temporaryFrame
                    |> Point2d.coordinates

            x2 =
                x2Ellipse / arguments.xRadius

            y2 =
                y2Ellipse / arguments.yRadius

            cx2 =
                x2 - 1

            cy2 =
                y2

            d =
                sqrt (cx2 * cx2 + cy2 * cy2) / 2
        in
        if d > 0 && d < 1 then
            let
                midAngle =
                    atan2 -cy2 -cx2

                offsetAngle =
                    acos d

                ( startAngle_, sweptAngleInRadians ) =
                    case arguments.sweptAngle of
                        Types.SmallPositive ->
                            ( midAngle + offsetAngle
                            , pi - 2 * offsetAngle
                            )

                        Types.SmallNegative ->
                            ( midAngle - offsetAngle
                            , -pi + 2 * offsetAngle
                            )

                        Types.LargePositive ->
                            ( midAngle - offsetAngle
                            , pi + 2 * offsetAngle
                            )

                        Types.LargeNegative ->
                            ( midAngle + offsetAngle
                            , -pi - 2 * offsetAngle
                            )

                centerPoint_ =
                    Point2d.fromCoordinatesIn temporaryFrame
                        ( arguments.xRadius * (1 - cos startAngle_)
                        , -arguments.yRadius * sin startAngle_
                        )
            in
            Just <|
                with
                    { centerPoint = centerPoint_
                    , xDirection = arguments.xDirection
                    , xRadius = arguments.xRadius
                    , yRadius = arguments.yRadius
                    , startAngle =
                        if startAngle_ > pi then
                            startAngle_ - 2 * pi
                        else if startAngle_ < -pi then
                            startAngle_ + 2 * pi
                        else
                            startAngle_
                    , sweptAngle = sweptAngleInRadians
                    }
        else
            Nothing
    else
        Nothing


{-| -}
centerPoint : EllipticalArc2d -> Point2d
centerPoint (Types.EllipticalArc2d arc) =
    Ellipse2d.centerPoint arc.ellipse


{-| -}
axes : EllipticalArc2d -> Frame2d
axes (Types.EllipticalArc2d arc) =
    Ellipse2d.axes arc.ellipse


{-| -}
xAxis : EllipticalArc2d -> Axis2d
xAxis (Types.EllipticalArc2d arc) =
    Ellipse2d.xAxis arc.ellipse


{-| -}
yAxis : EllipticalArc2d -> Axis2d
yAxis (Types.EllipticalArc2d arc) =
    Ellipse2d.yAxis arc.ellipse


{-| -}
xRadius : EllipticalArc2d -> Float
xRadius (Types.EllipticalArc2d arc) =
    Ellipse2d.xRadius arc.ellipse


{-| -}
yRadius : EllipticalArc2d -> Float
yRadius (Types.EllipticalArc2d arc) =
    Ellipse2d.yRadius arc.ellipse


{-| The start angle of an elliptical arc is the value of the [ellipse parameter](https://en.wikipedia.org/wiki/Ellipse#Parametric_representation)
at the start point of the arc.

    EllipticalArc2d.startAngle exampleArc
    --> 0

-}
startAngle : EllipticalArc2d -> Float
startAngle (Types.EllipticalArc2d arc) =
    arc.startAngle


{-| The swept angle of an elliptical arc is the difference between values of the
[ellipse parameter](https://en.wikipedia.org/wiki/Ellipse#Parametric_representation)
at the start and end points of the arc.

    EllipticalArc2d.sweptAngle exampleArc
    --> degrees 90

-}
sweptAngle : EllipticalArc2d -> Float
sweptAngle (Types.EllipticalArc2d arc) =
    arc.sweptAngle


{-| Get a point along an elliptical arc, based on a parameter that ranges from 0
to 1. A parameter value of 0 corresponds to the start point of the arc and a
value of 1 corresponds to the end point.

    EllipticalArc2d.pointOn exampleArc 0
    --> Point2d.fromCoordinates ( 2, 0 )

    EllipticalArc2d.pointOn exampleArc 0.5
    --> Point2d.fromCoordinates ( 1.4142, 0.7071 )

    EllipticalArc2d.pointOn exampleArc 1
    --> Point2d.fromCoordinates ( 0, 1 )

-}
pointOn : EllipticalArc2d -> ParameterValue -> Point2d
pointOn arc parameterValue =
    let
        t =
            ParameterValue.value parameterValue

        theta =
            startAngle arc + t * sweptAngle arc
    in
    Point2d.fromCoordinatesIn (axes arc)
        ( xRadius arc * cos theta
        , yRadius arc * sin theta
        )


{-| -}
pointsAt : List ParameterValue -> EllipticalArc2d -> List Point2d
pointsAt parameterValues arc =
    List.map (pointOn arc) parameterValues


{-| Get the derivative vector at a point along an elliptical arc, based on a
parameter that ranges from 0 to 1. A parameter value of 0 corresponds to the
derivative at the start point of the arc and a value of 1 corresponds to the
derivative at the end point.

    EllipticalArc2d.derivative exampleArc 0
    --> Vector2d.fromComponents ( 0, 1.5708 )

    EllipticalArc2d.derivative exampleArc 0.5
    --> Vector2d.fromComponents ( -2.2214, 1.1107 )

    EllipticalArc2d.derivative exampleArc 1
    --> Vector2d.fromComponents ( -3.1416, 0 )

-}
firstDerivative : EllipticalArc2d -> ParameterValue -> Vector2d
firstDerivative arc parameterValue =
    let
        t =
            ParameterValue.value parameterValue

        deltaTheta =
            sweptAngle arc

        theta =
            startAngle arc + t * deltaTheta
    in
    Vector2d.placeIn (axes arc) <|
        Vector2d.fromComponents
            ( -(xRadius arc) * deltaTheta * sin theta
            , yRadius arc * deltaTheta * cos theta
            )


{-| Convenient shorthand for evaluating multiple derivatives;

    EllipticalArc2d.derivatives arc parameterValues

is equivalent to

    List.map (EllipticalArc2d.derivative arc)
        parameterValues

To generate evenly-spaced parameter values, check out the [`Parameter`](Geometry-Parameter)
module.

-}
firstDerivativesAt : List ParameterValue -> EllipticalArc2d -> List Vector2d
firstDerivativesAt parameterValues arc =
    List.map (firstDerivative arc) parameterValues


{-| Sample an elliptical arc at a given parameter value to get both the position
and derivative vector at that parameter value;

    EllipticalArc2d.sample spline t

is equivalent to

    Maybe.map2 (,)
        (EllipticalArc2d.pointOn spline t)
        (EllipticalArc2d.derivative spline t)

-}
sampler : EllipticalArc2d -> Maybe (ParameterValue -> ( Point2d, Direction2d ))
sampler arc =
    let
        startAngle_ =
            startAngle arc

        sweptAngle_ =
            sweptAngle arc

        xRadius_ =
            xRadius arc

        yRadius_ =
            yRadius arc

        xDirection_ =
            xDirection arc

        yDirection_ =
            yDirection arc

        pointOnArc =
            pointOn arc
    in
    if sweptAngle_ == 0 then
        Nothing
    else if xRadius_ == 0 && yRadius_ == 0 then
        Nothing
    else if xRadius_ == 0 then
        let
            negativeXDirection =
                Direction2d.flip xDirection_
        in
        Just <|
            \parameterValue ->
                let
                    point =
                        pointOnArc parameterValue

                    t =
                        ParameterValue.value parameterValue

                    angle =
                        startAngle_ + t * sweptAngle_

                    tangentDirection =
                        if cos angle >= 0 then
                            xDirection_
                        else
                            negativeXDirection
                in
                ( point, tangentDirection )
    else if yRadius_ == 0 then
        let
            negativeYDirection =
                Direction2d.flip yDirection_
        in
        Just <|
            \parameterValue ->
                let
                    point =
                        pointOnArc parameterValue

                    t =
                        ParameterValue.value parameterValue

                    angle =
                        startAngle_ + t * sweptAngle_

                    tangentDirection =
                        if sin angle >= 0 then
                            negativeYDirection
                        else
                            yDirection_
                in
                ( point, tangentDirection )
    else
        Just <|
            \parameterValue ->
                let
                    point =
                        pointOnArc parameterValue

                    t =
                        ParameterValue.value parameterValue

                    angle =
                        startAngle_ + t * sweptAngle_

                    sinAngle =
                        sin angle

                    cosAngle =
                        cos angle

                    vx =
                        -xRadius_ * sinAngle

                    vy =
                        yRadius_ * cosAngle

                    -- Since xRadius_ and yRadius_ are both non-zero and at
                    -- least one of sinAngle or cosAngle must be non-zero, one
                    -- of vx or vy will always be non-zero and therefore
                    -- normalizing the vector (vx, vy) is safe
                    tangentDirection =
                        Vector2d.fromComponents ( vx, vy )
                            |> Vector2d.normalize
                            |> Vector2d.components
                            |> Direction2d.unsafe
                in
                ( point, tangentDirection )


{-| -}
samplesAt : List ParameterValue -> EllipticalArc2d -> List ( Point2d, Direction2d )
samplesAt parameterValues arc =
    case sampler arc of
        Just sampler_ ->
            List.map sampler_ parameterValues

        Nothing ->
            []


{-| Get the start point of an elliptical arc.

    EllipticalArc2d.startPoint exampleArc
    --> Point2d.fromCoordinates ( 2, 0 )

-}
startPoint : EllipticalArc2d -> Point2d
startPoint arc =
    pointOn arc ParameterValue.zero


{-| Get the end point of an elliptical arc.

    EllipticalArc2d.endPoint exampleArc
    --> Point2d.fromCoordinates ( 0, 1 )

-}
endPoint : EllipticalArc2d -> Point2d
endPoint arc =
    pointOn arc ParameterValue.one


{-| -}
xDirection : EllipticalArc2d -> Direction2d
xDirection arc =
    Frame2d.xDirection (axes arc)


{-| -}
yDirection : EllipticalArc2d -> Direction2d
yDirection arc =
    Frame2d.yDirection (axes arc)


{-| Reverse the direction of an elliptical arc, so that the start point becomes
the end point and vice versa. Does not change the shape of the arc or any
properties of the underlying ellipse.

    EllipticalArc2d.reverse exampleArc
    --> EllipticalArc2d.with
    -->     { centerPoint = Point2d.origin
    -->     , xDirection = Direction2d.x
    -->     , xRadius = 2
    -->     , yRadius = 1
    -->     , startAngle = degrees 90
    -->     , sweptAngle = degrees -90
    -->     }

-}
reverse : EllipticalArc2d -> EllipticalArc2d
reverse (Types.EllipticalArc2d properties) =
    Types.EllipticalArc2d
        { properties
            | startAngle = properties.startAngle + properties.sweptAngle
            , sweptAngle = -properties.sweptAngle
        }


transformBy : (Ellipse2d -> Ellipse2d) -> EllipticalArc2d -> EllipticalArc2d
transformBy ellipseTransformation (Types.EllipticalArc2d properties) =
    Types.EllipticalArc2d
        { properties | ellipse = ellipseTransformation properties.ellipse }


{-| Scale an elliptical arc about a given point by a given scale.

    exampleArc
        |> EllipticalArc2d.scaleAbout Point2d.origin 3
    --> EllipticalArc2d.with
    -->     { centerPoint = Point2d.origin
    -->     , xDirection = Direction2d.x
    -->     , xRadius = 6
    -->     , yRadius = 3
    -->     , startAngle = 0
    -->     , sweptAngle = degrees 90
    -->     }

-}
scaleAbout : Point2d -> Float -> EllipticalArc2d -> EllipticalArc2d
scaleAbout point scale =
    transformBy (Ellipse2d.scaleAbout point scale)


{-| Rotate an elliptical arc around a given point by a given angle (in radians).

    exampleArc
        |> EllipticalArc2d.rotateAround Point2d.origin
            (degrees 180)
    --> EllipticalArc2d.with
    -->     { centerPoint = Point2d.origin
    -->     , xDirection = Direction2d.negativeX
    -->     , xRadius = 2
    -->     , yRadius = 1
    -->     , startAngle = 0
    -->     , sweptAngle = degrees 90
    -->     }

-}
rotateAround : Point2d -> Float -> EllipticalArc2d -> EllipticalArc2d
rotateAround point angle =
    transformBy (Ellipse2d.rotateAround point angle)


{-| Translate an elliptical arc by a given displacement.

    exampleArc
        |> EllipticalArc2d.translateBy
            (Vector2d.fromComponents ( 2, 3 ))
    --> EllipticalArc2d.with
    -->     { centerPoint =
    -->         Point2d.fromCoordinates ( 2, 3 )
    -->     , xDirection = Direction2d.x
    -->     , xRadius = 2
    -->     , yRadius = 1
    -->     , startAngle = 0
    -->     , sweptAngle = degrees 90
    -->     }

-}
translateBy : Vector2d -> EllipticalArc2d -> EllipticalArc2d
translateBy displacement =
    transformBy (Ellipse2d.translateBy displacement)


{-| Translate an elliptical arc in a given direction by a given distance;

    EllipticalArc2d.translateIn direction distance

is equivalent to

    EllipticalArc2d.translateBy
        (Vector2d.withLength distance direction)

-}
translateIn : Direction2d -> Float -> EllipticalArc2d -> EllipticalArc2d
translateIn direction distance arc =
    translateBy (Vector2d.withLength distance direction) arc


{-| Mirror an elliptical arc across a given axis.

    mirroredArc =
        exampleArc
            |> EllipticalArc2d.mirrorAcross Axis2d.y

    EllipticalArc2d.startPoint mirroredArc
    --> Point2d.fromCoordinates ( -2, 0 )

    EllipticalArc2d.endPoint mirroredArc
    --> Point2d.fromCoordinates ( 0, 1 )

-}
mirrorAcross : Axis2d -> EllipticalArc2d -> EllipticalArc2d
mirrorAcross axis =
    transformBy (Ellipse2d.mirrorAcross axis)


{-| Take an elliptical arc defined in global coordinates, and return it expressed in
local coordinates relative to a given reference frame.

    localFrame =
        Frame2d.atPoint (Point2d.fromCoordinates ( 1, 2 ))

    EllipticalArc2d.relativeTo localFrame exampleArc
    --> EllipticalArc2d.with
    -->     { centerPoint =
    -->         Point2d.fromCoordinates ( -1, -2 )
    -->     , xDirection = Direction2d.x
    -->     , xRadius = 2
    -->     , yRadius = 1
    -->     , startAngle = 0
    -->     , sweptAngle = degrees 90
    -->     }

-}
relativeTo : Frame2d -> EllipticalArc2d -> EllipticalArc2d
relativeTo frame =
    transformBy (Ellipse2d.relativeTo frame)


{-| Take an elliptical arc considered to be defined in local coordinates
relative to a given reference frame, and return that arc expressed in global
coordinates.

    localFrame =
        Frame2d.atPoint (Point2d.fromCoordinates ( 1, 2 ))

    EllipticalArc2d.relativeTo localFrame exampleArc
    --> EllipticalArc2d.with
    -->     { centerPoint =
    -->         Point2d.fromCoordinates ( 1, 2 )
    -->     , xDirection = Direction2d.x
    -->     , xRadius = 2
    -->     , yRadius = 1
    -->     , startAngle = 0
    -->     , sweptAngle = degrees 90
    -->     }

-}
placeIn : Frame2d -> EllipticalArc2d -> EllipticalArc2d
placeIn frame =
    transformBy (Ellipse2d.placeIn frame)


{-| -}
maxSecondDerivativeMagnitude : EllipticalArc2d -> Float
maxSecondDerivativeMagnitude arc =
    let
        theta0 =
            startAngle arc

        dTheta =
            sweptAngle arc

        theta1 =
            theta0 + dTheta

        dThetaSquared =
            dTheta * dTheta

        rx =
            xRadius arc

        ry =
            yRadius arc

        kx =
            dThetaSquared * rx

        ky =
            dThetaSquared * ry

        thetaInterval =
            Interval.from theta0 theta1

        sinThetaInterval =
            Interval.sin thetaInterval

        includeKx =
            Interval.contains 0 sinThetaInterval

        includeKy =
            (Interval.maxValue sinThetaInterval == 1)
                || (Interval.minValue sinThetaInterval == -1)
    in
    if (kx >= ky) && includeKx then
        -- kx is the global max and is included in the arc
        kx
    else if (ky >= kx) && includeKy then
        -- ky is the global max and is included in the arc
        ky
    else
        -- global max is not included in the arc, so max must be at an endpoint
        let
            rxSquared =
                rx * rx

            rySquared =
                ry * ry

            cosTheta0 =
                cos theta0

            sinTheta0 =
                sin theta0

            cosTheta1 =
                cos theta1

            sinTheta1 =
                sin theta1

            d0 =
                (rxSquared * cosTheta0 * cosTheta0)
                    + (rySquared * sinTheta0 * sinTheta0)

            d1 =
                (rxSquared * cosTheta1 * cosTheta1)
                    + (rySquared * sinTheta1 * sinTheta1)
        in
        dThetaSquared * sqrt (max d0 d1)


{-| -}
derivativeMagnitude : EllipticalArc2d -> Float -> Float
derivativeMagnitude arc =
    let
        rx =
            xRadius arc

        ry =
            yRadius arc

        theta0 =
            startAngle arc

        dTheta =
            sweptAngle arc

        absDTheta =
            abs dTheta
    in
    \t ->
        let
            theta =
                theta0 + t * dTheta

            dx =
                rx * sin theta

            dy =
                ry * cos theta
        in
        absDTheta * sqrt (dx * dx + dy * dy)


{-| An elliptical arc that has been parameterized by arc length.
-}
type ArcLengthParameterized
    = ArcLengthParameterized EllipticalArc2d ArcLengthParameterization


{-| Build an arc length parameterization of the given elliptical arc, with a
given accuracy. Generally speaking, all operations on the resulting
`ArcLengthParameterized` value will be accurate to within the specified maximum
error.

    parameterizedArc =
        exampleArc
            |> EllipticalArc2d.arcLengthParameterized
                { maxError = 1.0e-4 }

-}
arcLengthParameterized : { maxError : Float } -> EllipticalArc2d -> ArcLengthParameterized
arcLengthParameterized { maxError } arc =
    let
        parameterization =
            ArcLengthParameterization.build
                { maxError = maxError
                , derivativeMagnitude = derivativeMagnitude arc
                , maxSecondDerivativeMagnitude =
                    maxSecondDerivativeMagnitude arc
                }
    in
    ArcLengthParameterized arc parameterization


{-| Find the total arc length of an elliptical arc. This will be accurate to
within the tolerance given when calling `arcLengthParameterized`.

    arcLength : Float
    arcLength =
        EllipticalArc2d.arcLength parameterizedArc

    arcLength
    --> 2.4221

-}
arcLength : ArcLengthParameterized -> Float
arcLength parameterizedArc =
    arcLengthParameterization parameterizedArc
        |> ArcLengthParameterization.totalArcLength


{-| Try to get the point along an elliptical arc at a given arc length. For
example, to get the true midpoint of `exampleArc`:

    EllipticalArc2d.pointAlong parameterizedArc
        (arcLength / 2)
    --> Just (Point2d.fromCoordinates ( 1.1889, 0.8041 ))

Note that this is not the same as evaulating at a parameter value of 0.5:

    EllipticalArc2d.pointOn exampleArc
        ParameterValue.oneHalf
    --> Point2d.fromCoordinates ( 1.4142, 0.7071 )

If the given arc length is less than zero or greater than the arc length of the
arc, `Nothing` is returned.

-}
pointAlong : ArcLengthParameterized -> Float -> Maybe Point2d
pointAlong (ArcLengthParameterized arc parameterization) distance =
    parameterization
        |> ArcLengthParameterization.arcLengthToParameterValue distance
        |> Maybe.map (pointOn arc)


{-| -}
sampleAlong : ArcLengthParameterized -> Float -> Maybe ( Point2d, Direction2d )
sampleAlong (ArcLengthParameterized arc parameterization) =
    case sampler arc of
        Just toSample ->
            \distance ->
                parameterization
                    |> ArcLengthParameterization.arcLengthToParameterValue
                        distance
                    |> Maybe.map toSample

        Nothing ->
            always Nothing


{-| -}
arcLengthParameterization : ArcLengthParameterized -> ArcLengthParameterization
arcLengthParameterization (ArcLengthParameterized _ parameterization) =
    parameterization


{-| -}
underlyingArc : ArcLengthParameterized -> EllipticalArc2d
underlyingArc (ArcLengthParameterized arc _) =
    arc
