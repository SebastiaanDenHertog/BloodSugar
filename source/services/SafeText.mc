import Toybox.Graphics;
import Toybox.System;
import Toybox.Math;
import Toybox.Lang;

module SafeText {
    function getSafeTextWidth(
        dc as Dc,
        centerY as Number,
        font as Graphics.FontType,
        edgeMargin as Number
    ) {
        var screenWidth = dc.getWidth() as Number;
        var screenHeight = dc.getHeight() as Number;
        var settings = System.getDeviceSettings();

        /*
         * Rectangular screens can use nearly the full width.
         */
        if (settings.screenShape == System.SCREEN_SHAPE_RECTANGLE) {
            return screenWidth - edgeMargin * 2;
        }

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
    ) {
        if (maxWidth <= 0) {
            return "";
        }

        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            return text;
        }

        var suffix = "...";
        var result = text;

        if (dc.getTextWidthInPixels(suffix, font) > maxWidth) {
            return "";
        }

        while (
            result.length() > 0 &&
            dc.getTextWidthInPixels(result + suffix, font) > maxWidth
        ) {
            result = result.substring(0, result.length() - 1);
        }

        return result + suffix;
    }

    /*
     * Draw text safely near the top of the screen.
     */
    function drawTop(dc as Dc, text as String) {
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
    ) {
        var screenHeight = dc.getHeight() as Number;

        var topPadding = (screenHeight * paddingPercent) / 100;

        drawFittedText(dc, text, topPadding, true);
    }

    /*
     * Draw text safely near the bottom of the screen.
     */
    function drawBottom(dc as Dc, text as String) {
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
    ) {
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
        isTop
    ) {
        var screenWidth = dc.getWidth() as Number;
        var screenHeight = dc.getHeight() as Number;
        var edgeMargin = (screenWidth * 3) / (100 as Number);

        var fonts = [
            Graphics.FONT_LARGE,
            Graphics.FONT_MEDIUM,
            Graphics.FONT_SMALL,
            Graphics.FONT_TINY,
            Graphics.FONT_XTINY,
        ];

        var selectedFont = Graphics.FONT_XTINY;
        var selectedCenterY = 0;
        var selectedWidth = 0;

        for (var i = 0; i < fonts.size(); i++) {
            var font = fonts[i];
            var fontHeight = dc.getFontHeight(font) as Number;
            var centerY;

            if (isTop) {
                centerY = padding + fontHeight / 2;
            } else {
                centerY = screenHeight - padding - fontHeight / 2;
            }

            var safeWidth =
                getSafeTextWidth(dc, centerY, font, edgeMargin) as Number;

            if (
                safeWidth > 0 &&
                dc.getTextWidthInPixels(text, font) <= safeWidth
            ) {
                selectedFont = font;
                selectedCenterY = centerY;
                selectedWidth = safeWidth;
                break;
            }

            /*
             * Save the smallest font as fallback.
             */
            if (i == fonts.size() - 1) {
                selectedFont = font;
                selectedCenterY = centerY;
                selectedWidth = safeWidth;
            }
        }

        if (selectedWidth <= 0) {
            return;
        }

        var visibleText = truncateText(dc, text, selectedFont, selectedWidth);

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
