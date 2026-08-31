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

/* Neutral configuration shared by foreground setup and background API code. */
module DexcomShareConfig {
    const US_SERVER = "https://share2.dexcom.com/ShareWebServices/Services/";
    const OUS_SERVER =
        "https://shareous1.dexcom.com/ShareWebServices/Services/";
    const JP_SERVER = "https://share.dexcom.jp/ShareWebServices/Services/";
    const DEFAULT_SERVER = OUS_SERVER;

    const STANDARD_APPLICATION_ID = "d89443d2-327c-4a6f-89e5-496bbb0317db";
    const JP_APPLICATION_ID = "d8665ade-9673-4e27-9ff6-92db4ce13d13";
}
