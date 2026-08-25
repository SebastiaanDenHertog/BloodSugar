/*
MIT License

Copyright (c) 2026 Sebastiaan den Hertog

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Toybox.Graphics;
import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

module SafeText {
    const FONT_COUNT = 5;
    const ELLIPSIS = "...";

    var _isRectangleCache as Boolean? = null;

    function isRectangleScreen() as Boolean {
        if (_isRectangleCache == null) {
            _isRectangleCache =
                System.getDeviceSettings().screenShape ==
                System.SCREEN_SHAPE_RECTANGLE;
        }

        return _isRectangleCache as Boolean;
    }

    function getCandidateFont(index as Number) as Graphics.FontType {
        if (index == 0) {
            return Graphics.FONT_LARGE;
        }

        if (index == 1) {
            return Graphics.FONT_MEDIUM;
        }

        if (index == 2) {
            return Graphics.FONT_SMALL;
        }

        if (index == 3) {
            return Graphics.FONT_TINY;
        }

        return Graphics.FONT_XTINY;
    }

    function getSafeTextWidth(
        dc as Dc,
        centerY as Number,
        font as Graphics.FontType,
        edgeMargin as Number
    ) as Number {
        return getSafeTextWidthForShape(
            dc,
            centerY,
            font,
            edgeMargin,
            isRectangleScreen()
        );
    }

    function getSafeTextWidthForShape(
        dc as Dc,
        centerY as Number,
        font as Graphics.FontType,
        edgeMargin as Number,
        isRectangle as Boolean
    ) as Number {
        var screenWidth = dc.getWidth() as Number;

        /*
         * Rectangular screens can use nearly the full width.
         */
        if (isRectangle) {
            return screenWidth - edgeMargin * 2;
        }

        var screenHeight = dc.getHeight() as Number;

        /*
         * Treat other screen shapes conservatively as round.
         */
        var diameter;

        if (screenWidth < screenHeight) {
            diameter = screenWidth;
        } else {
            diameter = screenHeight;
        }

        var radius = diameter / 2 - edgeMargin;
        var circleCenterY = screenHeight / 2;
        var fontHeight = dc.getFontHeight(font);

        /*
         * Check both the top and bottom edges of the text.
         */
        var textTop = centerY - fontHeight / 2;
        var textBottom = centerY + fontHeight / 2;

        var topDistance = textTop - circleCenterY;
        var bottomDistance = textBottom - circleCenterY;

        if (topDistance < 0) {
            topDistance = -topDistance;
        }

        if (bottomDistance < 0) {
            bottomDistance = -bottomDistance;
        }

        var largestDistance;

        if (topDistance > bottomDistance) {
            largestDistance = topDistance;
        } else {
            largestDistance = bottomDistance;
        }

        if (largestDistance >= radius) {
            return 0;
        }

        return Math.floor(
            2 * Math.sqrt(radius * radius - largestDistance * largestDistance)
        );
    }

    /*
     * Shorten text and add "..." when needed.
     */
    function truncateText(
        dc as Dc,
        text as String,
        font as Graphics.FontType,
        maxWidth as Number
    ) as String {
        if (maxWidth <= 0) {
            return "";
        }

        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            return text;
        }

        if (dc.getTextWidthInPixels(ELLIPSIS, font) > maxWidth) {
            return "";
        }

        /*
         * Find the longest fitting prefix in logarithmic time. This avoids
         * creating one shorter String for every character in long text.
         */
        var low = 0;
        var high = text.length();
        var bestLength = 0;

        while (low <= high) {
            var midpoint = (low + high) / 2;
            var prefix = text.substring(0, midpoint);

            if (prefix == null) {
                high = midpoint - 1;
                continue;
            }

            var candidate = prefix + ELLIPSIS;

            if (dc.getTextWidthInPixels(candidate, font) <= maxWidth) {
                bestLength = midpoint;
                low = midpoint + 1;
            } else {
                high = midpoint - 1;
            }
        }

        if (bestLength == 0) {
            return ELLIPSIS;
        }

        var result = text.substring(0, bestLength);

        if (result == null) {
            return ELLIPSIS;
        }

        return result + ELLIPSIS;
    }

    /*
     * Draw text safely near the top of the screen.
     */
    function drawTop(dc as Dc, text as String) as Void {
        drawTopWithPadding(dc, text, 10);
    }

    /*
     * Draw top text with configurable padding percentage.
     *
     * Example:
     * paddingPercent = 10 means 10% from the top.
     */
    function drawTopWithPadding(
        dc as Dc,
        text as String,
        paddingPercent as Number
    ) as Void {
        var screenHeight = dc.getHeight() as Number;

        var topPadding = (screenHeight * paddingPercent) / 100;

        drawFittedText(dc, text, topPadding, true);
    }

    /*
     * Draw text safely near the bottom of the screen.
     */
    function drawBottom(dc as Dc, text as String) as Void {
        drawBottomWithPadding(dc, text, 10);
    }

    /*
     * Draw bottom text with configurable padding percentage.
     *
     * Example:
     * paddingPercent = 10 means 10% above the bottom.
     */
    function drawBottomWithPadding(
        dc as Dc,
        text as String,
        paddingPercent as Number
    ) as Void {
        var screenHeight = dc.getHeight() as Number;

        var bottomPadding = (screenHeight * paddingPercent) / 100;

        drawFittedText(dc, text, bottomPadding, false);
    }

    /*
     * Shared implementation for top and bottom text.
     */
    function drawFittedText(
        dc as Dc,
        text as String,
        padding as Number,
        isTop as Boolean
    ) as Void {
        var screenWidth = dc.getWidth() as Number;
        var screenHeight = dc.getHeight() as Number;
        var edgeMargin = (screenWidth * 3) / 100;
        var isRectangle = isRectangleScreen();

        var selectedFont = Graphics.FONT_XTINY;
        var selectedCenterY = 0;
        var selectedWidth = 0;
        var selectedTextFits = false;

        for (var i = 0; i < FONT_COUNT; i++) {
            var font = getCandidateFont(i);
            var fontHeight = dc.getFontHeight(font) as Number;
            var centerY;

            if (isTop) {
                centerY = padding + fontHeight / 2;
            } else {
                centerY = screenHeight - padding - fontHeight / 2;
            }

            var safeWidth = getSafeTextWidthForShape(
                dc,
                centerY,
                font,
                edgeMargin,
                isRectangle
            );

            if (
                safeWidth > 0 &&
                dc.getTextWidthInPixels(text, font) <= safeWidth
            ) {
                selectedFont = font;
                selectedCenterY = centerY;
                selectedWidth = safeWidth;
                selectedTextFits = true;
                break;
            }

            /*
             * Save the smallest font as fallback.
             */
            if (i == FONT_COUNT - 1) {
                selectedFont = font;
                selectedCenterY = centerY;
                selectedWidth = safeWidth;
            }
        }

        if (selectedWidth <= 0) {
            return;
        }

        var visibleText = text;

        if (!selectedTextFits) {
            visibleText = truncateText(dc, text, selectedFont, selectedWidth);
        }

        if (visibleText.length() == 0) {
            return;
        }

        dc.drawText(
            screenWidth / 2,
            selectedCenterY,
            selectedFont,
            visibleText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
