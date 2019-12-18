module Elm.Comments exposing
    ( Comment, CommentPart(..), DocComment, FileComment
    , emptyComment, addPart
    , prettyDocComment, prettyFileComment
    , docCommentParser, fileCommentParser
    )

{-| A component DSL that helps with building comments.

It is useful to have this in a structured way, so that it can be re-flowed by
the pretty printer, and so that an understanding of the layout of the doc tags
can be extracted to order the exposing clause by.


# Structured comments

@docs Comment, CommentPart, DocComment, FileComment


# Building comments

@docs emptyComment, addPart


# Pretty printing of comments

@docs prettyDocComment, prettyFileComment


# Parsing of comments into structured comments

@docs docCommentParser, fileCommentParser

-}

import Parser exposing (Parser)
import Pretty exposing (Doc)


type DocComment
    = DocComment


type FileComment
    = FileComment


type Comment a
    = Comment (List CommentPart)


type CommentPart
    = Markdown String
    | Code String
    | DocTags (List String)


{-| Creates an empty comment of any type.
-}
emptyComment : Comment a
emptyComment =
    Comment []


{-| Adds a part to a comment.
-}
addPart : Comment a -> CommentPart -> Comment a
addPart (Comment parts) part =
    Comment (part :: parts)


{-| Gets the parts of a comment in the correct order.
-}
getParts : Comment a -> List CommentPart
getParts (Comment parts) =
    List.reverse parts


{-| Pretty prints a document comment.

Where possible the comment will be re-flowed to fit the specified page width.

-}
prettyDocComment : Int -> Comment DocComment -> String
prettyDocComment width comment =
    List.map prettyCommentPart (getParts comment)
        |> Pretty.lines
        |> delimeters
        |> Pretty.pretty width
        |> Debug.log "doc comment"


{-| Pretty prints a file comment.

Where possible the comment will be re-flowed to fit the specified page width.

-}
prettyFileComment : Int -> Comment FileComment -> ( String, List (List String) )
prettyFileComment width comment =
    ( List.map prettyCommentPart (getParts comment)
        |> Pretty.lines
        |> delimeters
        |> Pretty.pretty width
        |> Debug.log "doc comment"
    , []
    )


{-| Combines lists of doc tags that are together in the comment into single lists,
then breaks those lists up to fit the page width.
-}
layoutTags : Int -> List CommentPart -> ( List CommentPart, List (List String) )
layoutTags width parts =
    ( parts, [] )


prettyCommentPart : CommentPart -> Doc
prettyCommentPart part =
    case part of
        Markdown val ->
            prettyMarkdown val

        Code val ->
            prettyCode val

        DocTags tags ->
            prettyTags tags


prettyMarkdown val =
    -- List.map Pretty.string (String.words val)
    --     |> Pretty.join Pretty.softline
    -- Why is softline so slow?
    Pretty.string val


prettyCode val =
    Pretty.string val
        |> Pretty.indent 4


prettyTags tags =
    [ Pretty.string "@doc"
    , List.map Pretty.string tags
        |> Pretty.join (Pretty.string ", ")
    ]
        |> Pretty.words


partToStringAndTags : Int -> CommentPart -> ( String, List String )
partToStringAndTags width part =
    case part of
        Markdown val ->
            ( val, [] )

        Code val ->
            ( "    " ++ val, [] )

        DocTags tags ->
            ( "@doc " ++ String.join ", " tags, tags )


docCommentParser : Parser (Comment DocComment)
docCommentParser =
    Parser.getSource
        |> Parser.map (\val -> Comment [ Markdown val ])


fileCommentParser : Parser (Comment FileComment)
fileCommentParser =
    Parser.getSource
        |> Parser.map (\val -> Comment [ Markdown val ])


delimeters : Doc -> Doc
delimeters doc =
    Pretty.string "{-| "
        |> Pretty.a doc
        |> Pretty.a Pretty.line
        |> Pretty.a (Pretty.string "-}")
