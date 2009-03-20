//
//  ANSIEscapeHelper.h
//  AnsiColorsTest
//
//  Created by Ali Rantakari on 18.3.09.
//  Copyright 2009 Ali Rantakari. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// the CSI (Control Sequence Initiator) -- i.e. "escape sequence prefix".
// (add your own CSI:Miami joke here)
#define kANSIEscapeCSI			@"\033["

// the end byte of an SGR (Select Graphic Rendition)
// ANSI Escape Sequence
#define kANSIEscapeSGREnd		@"m"



/*!
 @enum			sgrCode
 
 @abstract		SGR (Select Graphic Rendition) ANSI control codes.
 */
enum sgrCode
{
	SGRCodeNoneOrInvalid =		-1,
	
	SGRCodeAllReset =			0,
	
	SGRCodeIntensityBold =		1,
	SGRCodeIntensityFaint =		2,
	SGRCodeIntensityNormal =	22,
	
	SGRCodeItalicOn =			3,
	
	SGRCodeUnderlineSingle =	4,
	SGRCodeUnderlineDouble =	21,
	SGRCodeUnderlineNone =		24,
	
	SGRCodeFgBlack =		30,
	SGRCodeFgRed =			31,
	SGRCodeFgGreen =		32,
	SGRCodeFgYellow =		33,
	SGRCodeFgBlue =			34,
	SGRCodeFgMagenta =		35,
	SGRCodeFgCyan =			36,
	SGRCodeFgWhite =		37,
	SGRCodeFgReset =		39,
	
	SGRCodeBgBlack =		40,
	SGRCodeBgRed =			41,
	SGRCodeBgGreen =		42,
	SGRCodeBgYellow =		43,
	SGRCodeBgBlue =			44,
	SGRCodeBgMagenta =		45,
	SGRCodeBgCyan =			46,
	SGRCodeBgWhite =		47,
	SGRCodeBgReset =		49
};






/*!
 @class		ANSIEscapeHelper
 
 @abstract	Contains helper methods for dealing with strings
			that contain ANSI escape sequences for formatting (colors,
			underlining, bold etc.)
 */
@interface ANSIEscapeHelper : NSObject
{
	NSFont *font;
	NSMutableDictionary *ansiColors;
}

/*!
 @property		font
 
 @abstract		The font to use when creating string formatting attribute values.
 */
@property(retain) NSFont *font;

/*!
 @property		ansiColors
 
 @abstract		The colors to use for displaying ANSI colors.
 
 @discussion	Keys in this dictionary should be NSNumber objects containing SGR code
				values from the sgrCode enum. The corresponding values for these keys
				should be NSColor objects. If this property is nil or if it doesn't
				contain a key for a specific SGR code, the default color will be used
				instead.
 */
@property(retain) NSMutableDictionary *ansiColors;



/*!
 @method		escapeCodesForString:cleanString:
 
 @abstract		
 
 @discussion	
 
 @param aString			A String containing ANSI escape sequences
 @param aCleanString	Upon return, contains a "clean" version of aString (i.e. aString
						without the ANSI escape sequences)
 
 @result		
 */
- (NSArray*) escapeCodesForString:(NSString*)aString cleanString:(NSString**)aCleanString;


/*!
 @method		ansiFormattedStringWithCodesAndLocations:cleanString:
 
 @abstract		
 
 @discussion	
 
 @param aCodesArray		
 @param aCleanString	
 
 @result		
 */
- (NSString*) ansiFormattedStringWithCodesAndLocations:(NSArray*)aCodesArray cleanString:(NSString*)aCleanString;


/*!
 @method		attributesForString:cleanString:
 
 @abstract		Convert ANSI escape sequences in a string to string formatting attributes.
 
 @discussion	Given a string with some ANSI escape sequences in it, this method returns
				attributes for formatting the specified string according to those ANSI
				escape sequences as well as a "clean" (i.e. free of the escape sequences)
				version of this string.
 
 @param aString			A String containing ANSI escape sequences
 @param aCleanString	Upon return, contains a "clean" version of aString (i.e. aString
						without the ANSI escape sequences)
 
 @result		An array containing NSDictionary objects, each of which has keys "range"
				(an NSValue containing an NSRange, specifying the range for the
				attribute within the "clean" version of aString), "attributeName" (an
				NSString) and "attributeValue" (an NSObject). You may use these as
				arguments for NSMutableAttributedString's methods for setting the
				visual formatting.
 */
- (NSArray*) attributesForString:(NSString*)aString cleanString:(NSString**)aCleanString;


/*!
 @method		sgrCode:endsFormattingIntroducedByCode:
 
 @abstract		Whether the occurrence of a given SGR code would end the formatting run
				introduced by another SGR code.
 
 @discussion	Formatting runs 
 
 @param endCode		The SGR code to test as a candidate for ending the formatting run
					introduced by startCode
 @param startCode	The SGR code that has introduced a formatting run
 
 @result		YES if the occurrence of endCode would end the formatting run
				introduced by startCode, NO otherwise.
 */
- (BOOL) sgrCode:(enum sgrCode)endCode endsFormattingIntroducedByCode:(enum sgrCode)startCode;


/*!
 @method		colorForSGRCode:
 
 @abstract		Returns the color to use for displaying a specific ANSI color.
 
 @param code	An SGR code that specifies an ANSI color.
 
 @result		The color to use for displaying the ANSI color specified by code.
 */
- (NSColor*) colorForSGRCode:(enum sgrCode)code;

@end
