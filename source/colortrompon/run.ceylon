import ceylon.html {
    Span
}
import ceylon.collection {
    HashMap
}
import ceylon.interop.dart {
    dartString, async, await
}
import ceylon.lexer.core {
    ErrorType, IdentifierType, IgnoredType, KeywordType, NumericLiteralType,
    StringLiteralType, characterLiteral, SymbolType, CeylonLexer, Token,
    TokenType, StringCharacterStream, uidentifier, lidentifier, lineComment,
    multiComment
}
import dart.html {
    querySelector, window, LinkElement, SelectElement, TextAreaElement,
    Event, HttpRequest
}

String codeUrl = "https://raw.githubusercontent.com/jvasileff/ColorTrompon/gh-pages/source/colortrompon/run.ceylon";

"Attach events. This function will be invoked when the page is loaded."
async shared void run() {
    updateCss();
    querySelector("#code").onChange.listen((_) => replaceCodeLabel());
    querySelector("#submit").onClick.listen(highlight);
    querySelector("#style").onChange.listen(updateCss);
    replaceCode();
}

"Replace the contents of the code textarea with the contents of [[codeUrl]]."
async void replaceCode() {
    value codeInput = querySelector("#code");

    "The code element must be a text area."
    assert (is TextAreaElement codeInput);

    try {
        value code = await(HttpRequest.getString(codeUrl));
        codeInput.\ivalue = code.string;
        replaceCodeLabel("Code (``codeUrl``)");
    }
    catch (Throwable e) {
        window.alert("Sorry, an error occurred attempting to fetch ``codeUrl``");
    }
}

"Replace the text content of the code textarea with [[newValue]]."
void replaceCodeLabel(String newValue = "Code")
    =>  querySelector("#codeLabel").text = newValue;

"Produce HTML for the given Ceylon [[code]]."
String colorTrompon(String code)
    =>  Span {
            for (token in CeylonTokenIterator(code))
            if (token.type.string == "whitespace") then
                // don’t put whitespace in a span –
                // this way, styles can use CSS selectors
                // based on the immediately previous node
                // without worrying about whitespace
                token.text
            else
                Span {
                    clazz = classes(token.type);
                    attributes =
                        if (token.type in [lidentifier, uidentifier,
                                lineComment, multiComment])
                        then ["content" -> token.text]
                        else [];
                    token.text
                }
        }.string;

"Handle click events for the 'Highlight' button."
void highlight(Event event) {
    event.preventDefault();

    // Find the elements we need
    value codeInput = querySelector("#code");
    value highlitElement = querySelector("#highlit");
    value highlitGroup = querySelector("#highlitGroup");

    "The code element must be a text area."
    assert (is TextAreaElement codeInput);

    // Convert the raw source code into HTML
    codeInput.disabled = true;
    value html = colorTrompon(codeInput.\ivalue);

    // Update the page
    highlitElement.setInnerHtml(html);
    highlitGroup.classes.remove(dartString("hidden"));
    codeInput.disabled = false;
}

"Handle change events for the 'Style' dropdown."
void updateCss(Event? event = null) {
    assert (is SelectElement styleInput = querySelector("#style"));
    value style = styleInput.\ivalue;

    assert (is LinkElement styleLink = querySelector("#styleLink"));
    styleLink.href = "css/" + style + ".css";
}

"Calculate and return the CSS classes for the given [[TokenType]] as a string.

 Results are cached so that at most one [[String]] is created per [[TokenType]]
 across multiple invocations of this function."
String(TokenType) classes = memoize((TokenType tokenType)
    =>  tokenType.string + (
            switch(tokenType)
            case (is ErrorType) " ErrorType"
            case (is IdentifierType) " IdentifierType"
            case (is IgnoredType) " IgnoredType"
            case (is KeywordType) " KeywordType"
            case (is NumericLiteralType) " NumericLiteralType"
            case (is StringLiteralType) " StringLiteralType"
            case (characterLiteral) ""
            case (is SymbolType) " KeywordType"));

"Create a lazy stream of [[Token]]s for the given Ceylon [[code]]."
class CeylonTokenIterator(String code) satisfies {Token*} {
    shared actual Iterator<Token> iterator()
        =>  CeylonLexer(StringCharacterStream(code));
}

"Create a cache for the given [[compute]] function."
Result(Argument) memoize<Result, Argument>
        (Result compute(Argument argument))
        given Argument satisfies Object
        given Result satisfies Object
    =>  let (cache = HashMap<Argument, Result>()) (
        (Argument argument) {
            if (exists result = cache.get(argument)) {
                return result;
            }
            else {
                value result = compute(argument);
                cache.put(argument, result);
                return result;
            }
        });
