/////////////////////////////////////////////////////////////////////////////////////////////////////////
//         _              _                __      __  _     _   _              //                //   //
//        | |       _    | |               \ \    / / | \   / | | |            // Marian Frische //    //
//        | |      |_|  _| |_               \ \  / /  |  \_/  | | |           //                //     //
//        | |       _  |_   _|  _____        \ \/ /   | |\_/| | | |          // 26.11.2011     //      //
//        | |      | |   | |   | ___ |        /  \    | |   | | | |         //                //       //
//        | |      | |   | |   |  ___|       / /\ \   | |   | | | |        // Version 0.8    //        //
//        | |____  | |   | |   | |___       / /  \ \  | |   | | | |____   //                //         //
//        |______| |_|   |_|   |_____|     /_/    \_\ |_|   |_| |______| // A8 8.30.5      //          //
//                                                                      //                //           //
/////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////
// Changelog                                                      //
//                                                                //
// 26.11.2011                                                     //
//      - first public release                                    //
//                                                                //
// Disclaimer                                                     //
//                                                                //
// This software is based on pugixml library (http://pugixml.org).//
// pugixml is Copyright (C) 2006-2010 Arseny Kapoulkine.          //
//                                                                //
////////////////////////////////////////////////////////////////////

#ifndef _LITEXML_H_
#define _LITEXML_H_

//////////////////////////////////////
//		 			 Defines					//
//////////////////////////////////////
#define XMLDOCUMENT	void*
#define XMLNODE		void*
#define XMLATTRIBUTE	void*


//////////////////////////////////////
//		  	 	Basic Functions			//
//////////////////////////////////////
/*
 * Deletes a node/attribute/document.
*/
void LXMLDeleteNode(XMLNODE* node);
void LXMLDeleteDocument(XMLDOCUMENT* doc);
void LXMLDeleteAttribute(XMLATTRIBUTE* attr);


//////////////////////////////////////
//		 	  Loading Functions			//
//////////////////////////////////////
/*
 * Loads an XML file from path.
 * file = filename (path possible) 
*/
XMLDOCUMENT LXMLLoadByChar(char* file);
XMLDOCUMENT LXMLLoadByString(STRING* file);

/*
 * Loads the content from the string and interprets it as an XML file.
 * xmlContent = the content from the XML. (Loaded from a buffer)
*/
XMLDOCUMENT LXMLLoadFromChar(char* xmlContent);
XMLDOCUMENT LXMLLoadFromString(char* xmlContent);


//////////////////////////////////////
//			Navigation Functions			//
//////////////////////////////////////
/*
 * Gets the root node of the xml file.
*/
XMLNODE LXMLMoveToRootNode(XMLDOCUMENT doc);


/*
 * Moves to a node.
 * Accepts variable arguments.
*/
XMLNODE LXMLMoveToNode(XMLDOCUMENT doc, int ArgAmount, STRING* ChildName, ...);

/*
 * Returns the parent of the given node.
 * Node = Node, you want the parent from.
*/
XMLNODE LXMLGetNodeParent(XMLNODE node);

/*
 * Returns the first child of the given node.
 * Node = Node, you want the child from.
*/
XMLNODE LXMLGetFirstChildNode(XMLNODE node);

/*
 * Returns the next sibling of a node.
 * Node = Node, you want the sibling from.
*/
XMLNODE LXMLGetNextSiblingNode(XMLNODE node);


//////////////////////////////////////
//		  Get Attribute Functions		//
//////////////////////////////////////
/*
 * Returns the name of an attribute.
*/
char* LXMLGetAttributeNameAsChar(XMLATTRIBUTE attr);
STRING* LXMLGetAttributeNameAsString(XMLATTRIBUTE attr);

/*
 * Returns the value of an attribute.
*/
char* LXMLGetAttributeValueAsChar(XMLATTRIBUTE attr);
STRING* LXMLGetAttributeValueAsString(XMLATTRIBUTE attr);

/*
 * Gets the first attribute from a node.
*/
XMLATTRIBUTE LXMLGetFirstAttribute(XMLNODE node);

/*
 * Gets the attribute in the list of attributes of a node after the given one.
*/
XMLATTRIBUTE LXMLGetNextAttribute(XMLATTRIBUTE attr);

/*
 * Gets the attribute in the list of attributes of a node before the given one.
*/
XMLATTRIBUTE LXMLGetPreviousAttribute(XMLATTRIBUTE attr);


/*
 * Returns the attribute with the given name from a given name.
*/
XMLATTRIBUTE LXMLGetAttributeByChar(XMLNODE node, char* attrName);
XMLATTRIBUTE LXMLGetAttributeByString(XMLNODE node, STRING* attrName);


//////////////////////////////////////
//		  GetChildValue Functions		//
//////////////////////////////////////
/*
 * Returns the value of a child as a string.
*/
STRING* LXMLGetChildValueAsString(XMLNODE node, char* ParameterName);

/*
 * Returns the value of a child as an int.
*/
int LXMLGetChildValueAsInt(XMLNODE node, char* ParameterName);

/*
 * Returns the value of a child as a float.
*/
float LXMLGetChildValueAsFloat(XMLNODE node, char* ParameterName);

/*
 * Returns the value of a child as a double.
*/
double LXMLGetChildValueAsDouble(XMLNODE node, char* ParameterName);

/*
 * Returns the value of a child as a char.
*/
char* LXMLGetChildValueAsChar(XMLNODE node, char* ParameterName);


//////////////////////////////////////
//				Debug Functions			//
//////////////////////////////////////
/*
 * Creates/Appends the tree structure of the xml into the LiteXML.log file.
*/
void LXMLDebugPrintWalker(XMLNODE doc);


#endif