{- This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, you can
   obtain one at http://mozilla.org/MPL/2.0/.

   Copyright 2016 by Ian Mackenzie
   ian.e.mackenzie@gmail.com
-}


module Point2d exposing (suite)

import Test exposing (Test)
import Test.Runner.Html as Html
import OpenSolid.Point2d as Point2d
import OpenSolid.Fuzz as Fuzz
import OpenSolid.Fuzz.Point2d as Fuzz
import OpenSolid.Fuzz.Axis2d as Fuzz
import OpenSolid.Expect as Expect
import OpenSolid.Expect.Point2d as Expect
import Generic


rotationPreservesDistance : Test
rotationPreservesDistance =
    let
        description =
            "Rotating about a point preserves distance from that point"

        expectation point centerPoint rotationAngle =
            let
                initialDistance =
                    Point2d.distanceFrom centerPoint point

                rotatedPoint =
                    Point2d.rotateAround centerPoint rotationAngle point

                rotatedDistance =
                    Point2d.distanceFrom centerPoint rotatedPoint
            in
                Expect.approximately initialDistance rotatedDistance
    in
        Test.fuzz3 Fuzz.point2d Fuzz.point2d Fuzz.scalar description expectation


projectionOntoAxisPreservesDistance : Test
projectionOntoAxisPreservesDistance =
    let
        description =
            "Projection onto axis preserves distance along that axis"

        expectation point axis =
            let
                distance =
                    Point2d.signedDistanceAlong axis point

                projectedPoint =
                    Point2d.projectOnto axis point

                projectedDistance =
                    Point2d.signedDistanceAlong axis projectedPoint
            in
                Expect.approximately projectedDistance distance
    in
        Test.fuzz2 Fuzz.point2d Fuzz.axis2d description expectation


jsonRoundTrips : Test
jsonRoundTrips =
    Generic.jsonRoundTrips Fuzz.point2d Point2d.encode Point2d.decoder


suite : Test
suite =
    Test.describe "OpenSolid.Core.Point2d"
        [ rotationPreservesDistance
        , projectionOntoAxisPreservesDistance
        , jsonRoundTrips
        ]


main : Program Never
main =
    Html.run suite