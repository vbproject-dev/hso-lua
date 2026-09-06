The server executables are placed alongside the `Assets` directory. The `Assets` directory contains the `src` folder for scripts and the `res` folder for game resources.

Example directory structure:

```text
Server/
├── Server-linux           # Linux server (Ubuntu 22.04 or newer)
├── Server-win64.exe       # Windows server
└── Assets/
    ├── src/               # Scripts
    └── res/               # Game resources
```

This project is still under active development, and contributions are welcome! If you'd like to help, feel free to fork the repository, submit a pull request, report bugs, or suggest improvements. All contributions and feedback are greatly appreciated.

# API

# GServer class exposed as server

| Method                | Description                          |
| --------------------- | ------------------------------------ |
| `start()`             | Starts the server                    |
| `stop()`              | Stops the server                     |
| `isRunning()`         | Checks whether the server is running |
| `pollEvents()`        | Processes pending server events      |
| `setPort(port)`       | Sets the server port                 |
| `port()`              | Gets the server port                 |
| `useDefaultCodec()`   | Enables the default packet codec     |
| `sessionCount()`      | Gets the number of active sessions   |
| `getSession(id)`      | Gets a session by ID                 |
| `setHandler(handler)` | Sets the server event handler        |

# GameSession class
| Method               | Description                        |
| -------------------- | ---------------------------------- |
| `id()`               | Gets the session ID                |
| `getRemoteAddress()` | Gets the remote client address     |
| `isOpen()`           | Checks whether the session is open |
| `send(packet)`       | Sends a packet to the client       |
| `close()`            | Closes the session                 |
| `set(key, value)`    | Stores a value in the session      |
| `get(key)`           | Gets a stored session value        |

# GameClient class

| Method                | Description                           |
| --------------------- | ------------------------------------- |
| `GameClient()`        | Creates a new game client             |
| `useHso()`            | Uses the HSO codec                    |
| `useAvatar()`         | Uses the Avatar codec                 |
| `connect()`           | Connects to the server                |
| `pollEvents()`        | Processes pending network events      |
| `send(packet)`        | Sends a packet to the server          |
| `close()`             | Closes the connection                 |
| `isOpen()`            | Checks whether the connection is open |
| `isStarted()`         | Checks whether the client has started |
| `isReady()`           | Checks whether the client is ready    |
| `getRemoteAddress()`  | Gets the remote server address        |
| `setHandler(handler)` | Sets the client event handler         |

### Handler table

`setHandler(handler)` accepts a Lua table containing optional event callbacks:

| Field          | Description                                        |
| -------------- | -------------------------------------------------- |
| `onConnect`    | Called when the client connects to the server      |
| `onDisconnect` | Called when the client disconnects from the server |
| `onMessage`    | Called when a packet is received from the server   |

Example:

```lua
client:setHandler({
    onConnect = function(client)
        -- connected
    end,

    onDisconnect = function(client)
        -- disconnected
    end,

    onMessage = function(client, packet)
        -- received packet
    end
})
```

# Packet class
| Method                      | Description                            |
| --------------------------- | -------------------------------------- |
| `Packet()`                  | Creates an empty packet                |
| `Packet(cmd)`               | Creates a packet with a command        |
| `Packet(cmd, data)`         | Creates a packet with command and data |
| `getCmd()`                  | Gets command/type                      |
| `setCmd(cmd)`               | Sets command/type                      |
| `readByte()`                | Reads signed byte                      |
| `readUnsignedByte()`        | Reads unsigned byte                    |
| `readShort()`               | Reads signed 16-bit integer            |
| `readUnsignedShort()`       | Reads unsigned 16-bit integer          |
| `readInt()`                 | Reads signed 32-bit integer            |
| `readUnsignedInt()`         | Reads unsigned 32-bit integer          |
| `readLong()`                | Reads signed 64-bit integer            |
| `readUnsignedLong()`        | Reads unsigned 64-bit integer          |
| `readFloat()`               | Reads 32-bit float                     |
| `readDouble()`              | Reads 64-bit double                    |
| `readBoolean()`             | Reads boolean                          |
| `readUTF()`                 | Reads UTF string                       |
| `readBytes(length)`         | Reads raw bytes                        |
| `writeByte(value)`          | Writes signed byte                     |
| `writeUnsignedByte(value)`  | Writes unsigned byte                   |
| `writeShort(value)`         | Writes signed 16-bit integer           |
| `writeUnsignedShort(value)` | Writes unsigned 16-bit integer         |
| `writeInt(value)`           | Writes signed 32-bit integer           |
| `writeUnsignedInt(value)`   | Writes unsigned 32-bit integer         |
| `writeLong(value)`          | Writes signed 64-bit integer           |
| `writeUnsignedLong(value)`  | Writes unsigned 64-bit integer         |
| `writeFloat(value)`         | Writes 32-bit float                    |
| `writeDouble(value)`        | Writes 64-bit double                   |
| `writeBoolean(value)`       | Writes boolean                         |
| `writeUTF(value)`           | Writes UTF string                      |
| `writeBytes(value)`         | Writes raw bytes                       |
| `getPosition()`             | Gets current position                  |
| `setPosition(position)`     | Sets current position                  |
| `getSize()`                 | Gets packet size                       |
| `hasMore()`                 | Checks if more data is available       |
| `skip(length)`              | Skips the specified number of bytes    |
| `available()`               | Gets remaining unread bytes            |
| `reset()`                   | Resets position to the beginning       |
| `getData()`                 | Gets packet data as a binary string    |
| `clear()`                   | Clears packet data                     |

# ArrayList class
| Method                     | Description                                                   |
| -------------------------- | ------------------------------------------------------------- |
| `ArrayList.new()`          | Creates an empty ArrayList                                    |
| `ArrayList.new(values)`    | Creates an ArrayList from a Lua table                         |
| `add(value)`               | Adds a value to the end                                       |
| `insert(index, value)`     | Inserts a value at the specified index                        |
| `removeAt(index)`          | Removes and returns the value at the index                    |
| `remove(value)`            | Removes the specified value                                   |
| `clear()`                  | Removes all values                                            |
| `get(index)`               | Gets the value at the index                                   |
| `set(index, value)`        | Replaces the value at the index                               |
| `first()`                  | Gets the first value                                          |
| `last()`                   | Gets the last value                                           |
| `size()`                   | Gets the number of values                                     |
| `isEmpty()`                | Checks whether the list is empty                              |
| `contains(value)`          | Checks whether the list contains a value                      |
| `indexOf(value)`           | Gets the first index of a value                               |
| `lastIndexOf(value)`       | Gets the last index of a value                                |
| `sort()`                   | Sorts values in ascending order                               |
| `sort(comparator)`         | Sorts values using a comparator function                      |
| `forEach(callback)`        | Executes a callback for each value                            |
| `forEachIndexed(callback)` | Executes a callback with index and value                      |
| `ipairs()`                 | Returns an iterator for the list                              |
| `filter(predicate)`        | Returns values matching the predicate                         |
| `map(mapper)`              | Creates a list by transforming each value                     |
| `reduce(initial, reducer)` | Reduces the list to a single value                            |
| `anyMatch(predicate)`      | Checks whether any value matches                              |
| `allMatch(predicate)`      | Checks whether all values match                               |
| `noneMatch(predicate)`     | Checks whether no values match                                |
| `countIf(predicate)`       | Counts values matching the predicate                          |
| `findFirst(predicate)`     | Finds the first value matching the predicate                  |
| `distinct()`               | Returns a list containing distinct values                     |
| `reversed()`               | Returns the list in reverse order                             |
| `take(count)`              | Returns the first specified number of values                  |
| `drop(count)`              | Returns the list without the first specified number of values |
| `takeWhile(predicate)`     | Takes values while the predicate is true                      |
| `dropWhile(predicate)`     | Drops values while the predicate is true                      |
| `toTable(predicate)`       | Convert into a lua table                                      |

# JSON class
| Method                  | Description                           |
| ----------------------- | ------------------------------------- |
| `JSON.toTable(text)`    | Parses a JSON string into a Lua table |
| `JSON.fromTable(table)` | Converts a Lua table into a JSON stri |

# FileUtils class
| Method                                | Description                                      |
| ------------------------------------- | ------------------------------------------------ |
| `getFileInfo(filename)`               | Gets information about a file or directory       |
| `addSearchPath(path)`                 | Adds a search path                               |
| `removeSearchPath(path)`              | Removes a search path                            |
| `clearSearchPaths()`                  | Removes all search paths                         |
| `getSearchPaths()`                    | Gets all registered search paths                 |
| `findFile(filename)`                  | Finds a file using the configured search paths   |
| `exists(filename)`                    | Checks whether a file exists                     |
| `readText(filename)`                  | Reads a file as text                             |
| `readBytes(filename)`                 | Reads a file as raw bytes                        |
| `writeText(filename, text)`           | Writes text to a file                            |
| `writeText(filename, text, append)`   | Writes text to a file, optionally appending      |
| `writeBytes(filename, bytes)`         | Writes raw bytes to a file                       |
| `writeBytes(filename, bytes, append)` | Writes raw bytes to a file, optionally appending |
| `createDirectory(path)`               | Creates a directory                              |
| `directoryExists(path)`               | Checks whether a directory exists                |
| `listDirectory(path)`                 | Lists entries in a directory                     |
| `listFiles(path)`                     | Lists files in a directory recursively           |
| `listFiles(path, recursive)`          | Lists files with optional recursion              |
| `removeFile(path)`                    | Removes a file                                   |
| `removeDirectory(path)`               | Removes a directory                              |
| `removeDirectory(path, recursive)`    | Removes a directory, optionally recursively      |
| `copyFile(source, destination)`       | Copies a file to another path                    |
| `renamePath(source, destination)`     | Renames or moves a file or directory             |

# MYSQL class
| Method                                                                               | Description                                    |
| ------------------------------------------------------------------------------------ | ---------------------------------------------- |
| `MysqlConnection.createConnection(host, user, password, database, port)`             | Creates a MySQL connection                     |
| `MysqlConnection.createConnection(host, user, password, database, port, unixSocket)` | Creates a MySQL connection using a Unix socket |
| `query(sql)`                                                                         | Executes a SQL query                           |
| `fetchAll()`                                                                         | Fetches all rows from the last query result    |
| `ping()`                                                                             | Checks whether the connection is alive         |
| `close()`                                                                            | Closes the connection                          |
| `isOpen()`                                                                           | Checks whether the connection is open          |
| `affectedRows()`                                                                     | Gets the number of affected rows               |
| `insertId()`                                                                         | Gets the ID generated by the last insert       |
| `errno()`                                                                            | Gets the MySQL error number                    |
| `error()`                                                                            | Gets the last MySQL error message              |


# Graphics class

| Method                                                                           | Description                                  |
| -------------------------------------------------------------------------------- | -------------------------------------------- |
| `setColor(color)`                                                                | Sets the current drawing color               |
| `setColor(r, g, b)`                                                              | Sets the current RGB drawing color           |
| `setColor(r, g, b, a)`                                                           | Sets the current RGBA drawing color          |
| `setAlpha(alpha)`                                                                | Sets the current alpha value                 |
| `getAlpha()`                                                                     | Gets the current alpha value                 |
| `setGrayScale(gray)`                                                             | Sets the grayscale rendering value           |
| `getColor()`                                                                     | Gets the current drawing color               |
| `getRedComponent()`                                                              | Gets the red color component                 |
| `getGreenComponent()`                                                            | Gets the green color component               |
| `getBlueComponent()`                                                             | Gets the blue color component                |
| `setFont(font)`                                                                  | Sets the current font                        |
| `getFont()`                                                                      | Gets the current font                        |
| `setBitmapFont(font)`                                                            | Sets the current bitmap font                 |
| `getBitmapFont()`                                                                | Gets the current bitmap font                 |
| `translate(x, y)`                                                                | Translates the drawing coordinate system     |
| `scale(x, y)`                                                                    | Scales the drawing coordinate system         |
| `rotate(angle)`                                                                  | Rotates the drawing coordinate system        |
| `save()`                                                                         | Saves the current graphics state             |
| `restore()`                                                                      | Restores the previously saved graphics state |
| `beginCamera(camera)`                                                            | Begins rendering using a camera              |
| `endCamera()`                                                                    | Ends camera rendering                        |
| `getActiveCamera()`                                                              | Gets the active camera                       |
| `setBlendMode(mode)`                                                             | Sets the blend mode                          |
| `getBlendMode()`                                                                 | Gets the current blend mode                  |
| `setClip(x, y, width, height)`                                                   | Sets the clipping region                     |
| `clipRect(x, y, width, height)`                                                  | Intersects the current clipping region       |
| `drawLine(x1, y1, x2, y2)`                                                       | Draws a line                                 |
| `drawRect(x, y, width, height)`                                                  | Draws a rectangle outline                    |
| `fillRect(x, y, width, height)`                                                  | Draws a filled rectangle                     |
| `drawRoundRect(x, y, width, height, arcWidth, arcHeight)`                        | Draws a rounded rectangle outline            |
| `fillRoundRect(x, y, width, height, arcWidth, arcHeight)`                        | Draws a filled rounded rectangle             |
| `drawArc(x, y, width, height, startAngle, arcAngle)`                             | Draws an arc outline                         |
| `fillArc(x, y, width, height, startAngle, arcAngle)`                             | Draws a filled arc                           |
| `fillTriangle(x1, y1, x2, y2, x3, y3)`                                           | Draws a filled triangle                      |
| `drawOval(x, y, width, height)`                                                  | Draws an oval outline                        |
| `fillOval(x, y, width, height)`                                                  | Draws a filled oval                          |
| `drawCircle(x, y, radius)`                                                       | Draws a circle outline                       |
| `fillCircle(x, y, radius)`                                                       | Draws a filled circle                        |
| `drawString(text, x, y, anchor)`                                                 | Draws text using the current font            |
| `drawChar(character, x, y, anchor)`                                              | Draws a single character                     |
| `drawSubstring(text, offset, length, x, y, anchor)`                              | Draws part of a string                       |
| `drawChars(chars, offset, length, x, y, anchor)`                                 | Draws characters                             |
| `drawBitmapString(text, x, y, anchor)`                                           | Draws text using the current bitmap font     |
| `drawImage(image, x, y, anchor)`                                                 | Draws an image                               |
| `drawImageScale(image, x, y, width, height, anchor)`                             | Draws a scaled image                         |
| `drawRegion(image, sx, sy, sw, sh, transform, x, y, anchor)`                     | Draws an image region                        |
| `drawRegionScale(image, sx, sy, sw, sh, transform, x, y, width, height, anchor)` | Draws and scales an image region             |
| `draw9Sprite(image, ...)`                                                        | Draws a scalable 9-slice sprite              |
| `copyArea(x, y, width, height, dx, dy, anchor)`                                  | Copies a rendering area                      |
| `setStrokeStyle(style)`                                                          | Sets the stroke style                        |
| `getStrokeStyle()`                                                               | Gets the stroke style                        |
| `setTextInputArea(x, y, width, height)`                                          | Sets the text input area                     |
| `clearTextInputArea()`                                                           | Clears the text input area                   |

# Graphics anchors

| Constant                 | Description                 |
| ------------------------ | --------------------------- |
| `Graphics.LEFT`          | Left alignment              |
| `Graphics.HCENTER`       | Horizontal center alignment |
| `Graphics.RIGHT`         | Right alignment             |
| `Graphics.TOP`           | Top alignment               |
| `Graphics.VCENTER`       | Vertical center alignment   |
| `Graphics.BOTTOM`        | Bottom alignment            |
| `Graphics.TOP_LEFT`      | Top-left anchor             |
| `Graphics.TOP_CENTER`    | Top-center anchor           |
| `Graphics.TOP_RIGHT`     | Top-right anchor            |
| `Graphics.CENTER_LEFT`   | Center-left anchor          |
| `Graphics.CENTER`        | Center anchor               |
| `Graphics.CENTER_RIGHT`  | Center-right anchor         |
| `Graphics.BOTTOM_LEFT`   | Bottom-left anchor          |
| `Graphics.BOTTOM_CENTER` | Bottom-center anchor        |
| `Graphics.BOTTOM_RIGHT`  | Bottom-right anchor         |

# Graphics transform constants

| Constant                       | Description                   |
| ------------------------------ | ----------------------------- |
| `Graphics.TRANS_NONE`          | No transformation             |
| `Graphics.TRANS_ROT90`         | Rotate 90 degrees             |
| `Graphics.TRANS_ROT180`        | Rotate 180 degrees            |
| `Graphics.TRANS_ROT270`        | Rotate 270 degrees            |
| `Graphics.TRANS_MIRROR`        | Mirror                        |
| `Graphics.TRANS_MIRROR_ROT90`  | Mirror and rotate 90 degrees  |
| `Graphics.TRANS_MIRROR_ROT180` | Mirror and rotate 180 degrees |
| `Graphics.TRANS_MIRROR_ROT270` | Mirror and rotate 270 degrees |

# Graphics blend modes

| Constant              | Description             |
| --------------------- | ----------------------- |
| `Graphics.BLEND_MIX`  | Standard alpha blending |
| `Graphics.BLEND_ADD`  | Additive blending       |
| `Graphics.BLEND_MOD`  | Modulation blending     |
| `Graphics.BLEND_MUL`  | Multiplicative blending |
| `Graphics.BLEND_NONE` | No blending             |

# Font class

| Method                                 | Description                     |
| -------------------------------------- | ------------------------------- |
| `Font.create(path, style, size)`       | Creates a font from a font file |
| `getBaselinePosition()`                | Gets the baseline position      |
| `getHeight()`                          | Gets the font height            |
| `charWidth(character)`                 | Gets the width of a character   |
| `stringWidth(text)`                    | Gets the width of a string      |
| `substringWidth(text, offset, length)` | Gets the width of a substring   |
| `setFontSize(size)`                    | Changes the font size           |
| `getFontSize()`                        | Gets the current font size      |
| `setStyle(style)`                      | Sets the font style             |
| `getStyle()`                           | Gets the current font style     |
| `setOutline(outline)`                  | Enables or sets font outline    |
| `getOutline()`                         | Gets the font outline setting   |

# FontStyle enum

| Constant                  | Description        |
| ------------------------- | ------------------ |
| `FontStyle.PLAIN`         | Normal font        |
| `FontStyle.BOLD`          | Bold font          |
| `FontStyle.ITALIC`        | Italic font        |
| `FontStyle.UNDERLINE`     | Underlined font    |
| `FontStyle.STRIKETHROUGH` | Strikethrough font |

# BitmapFont class

| Method                      | Description                                |
| --------------------------- | ------------------------------------------ |
| `BitmapFont.create(path)`   | Creates a bitmap font from a font resource |
| `getLineHeight()`           | Gets the bitmap font line height           |
| `stringWidth(text)`         | Gets the width of a string                 |
| `getKerning(first, second)` | Gets kerning between two characters        |
| `getGlyph(charID)`          | Gets the glyph information for a character |

# BitmapGlyph class

| Property   | Description                                 |
| ---------- | ------------------------------------------- |
| `x`        | Glyph X position in the bitmap font texture |
| `y`        | Glyph Y position in the bitmap font texture |
| `width`    | Glyph width                                 |
| `height`   | Glyph height                                |
| `xOffset`  | Horizontal drawing offset                   |
| `yOffset`  | Vertical drawing offset                     |
| `xAdvance` | Horizontal advance after drawing the glyph  |
| `page`     | Bitmap font texture page                    |

# Image class

| Method                              | Description                             |
| ----------------------------------- | --------------------------------------- |
| `Image.createImage(width, height)`  | Creates an empty image                  |
| `Image.createImage(path)`           | Loads an image from a file              |
| `Image.createImageFromBytes(bytes)` | Creates an image from binary image data |
| `getWidth()`                        | Gets the image width                    |
| `getHeight()`                       | Gets the image height                   |

# Camera class

| Method                           | Description                                      |
| -------------------------------- | ------------------------------------------------ |
| `Camera(width, height)`          | Creates a camera                                 |
| `setPosition(x, y)`              | Sets the camera position                         |
| `move(x, y)`                     | Moves the camera                                 |
| `getX()`                         | Gets the camera X position                       |
| `getY()`                         | Gets the camera Y position                       |
| `getPosition()`                  | Gets the camera position as `Vec2`               |
| `setZoom(zoom)`                  | Sets the camera zoom                             |
| `zoomBy(amount)`                 | Changes the camera zoom                          |
| `getZoom()`                      | Gets the camera zoom                             |
| `setRotation(rotation)`          | Sets the camera rotation                         |
| `getRotation()`                  | Gets the camera rotation                         |
| `setViewportSize(width, height)` | Sets the viewport size                           |
| `getViewportWidth()`             | Gets the viewport width                          |
| `getViewportHeight()`            | Gets the viewport height                         |
| `setBounds(x, y, width, height)` | Sets camera movement bounds                      |
| `clearBounds()`                  | Removes camera bounds                            |
| `hasBounds()`                    | Checks whether camera bounds are enabled         |
| `follow(target)`                 | Makes the camera follow an object                |
| `snapTo(target)`                 | Immediately moves the camera to a target         |
| `shake(duration, intensity)`     | Shakes the camera                                |
| `update(dt)`                     | Updates camera state                             |
| `worldToScreen(x, y)`            | Converts world coordinates to screen coordinates |
| `screenToWorld(x, y)`            | Converts screen coordinates to world coordinates |
| `getEffectivePosition()`         | Gets the camera position including effects       |
| `getViewport()`                  | Gets the camera viewport                         |

# Vec2 class

| Property / Method | Description                   |
| ----------------- | ----------------------------- |
| `Vec2()`          | Creates a zero vector         |
| `Vec2(x, y)`      | Creates a vector with X and Y |
| `x`               | X coordinate                  |
| `y`               | Y coordinate                  |


# Input class

| Method                             | Description                                                      |
| ---------------------------------- | ---------------------------------------------------------------- |
| `Input.isPointerPressed()`         | Returns `true` when a pointer press event occurred.              |
| `Input.isPointerReleased()`        | Returns `true` when a pointer release event occurred.            |
| `Input.isPointerDragged()`         | Returns `true` when a pointer drag event occurred.               |
| `Input.isKeyPressed()`             | Returns `true` when a key press event occurred.                  |
| `Input.isKeyReleased()`            | Returns `true` when a key release event occurred.                |
| `Input.getKey()`                   | Returns the key code associated with the current keyboard event. |
| `Input.getX()`                     | Returns the current pointer X coordinate.                        |
| `Input.getY()`                     | Returns the current pointer Y coordinate.                        |
| `Input.setInputCallback(callback)` | Registers a callback that receives SDL text input as UTF-8 text. |
| `Input.clearInputCallback()`       | Removes the current text-input callback.                         |
| `Input.startInput()`               | Starts SDL text input for the application's window.              |
| `Input.stopInput()`                | Stops SDL text input for the application's window.               |

# Key Codes

| Constant                            | Description                     |
| ----------------------------------- | ------------------------------- |
| `Input.KEY_UNKNOWN`                 | Unknown key.                    |
| `Input.KEY_RETURN`                  | Return/Enter key.               |
| `Input.KEY_ESCAPE`                  | Escape key.                     |
| `Input.KEY_BACKSPACE`               | Backspace key.                  |
| `Input.KEY_TAB`                     | Tab key.                        |
| `Input.KEY_SPACE`                   | Space key.                      |
| `Input.KEY_EXCLAIM`                 | Exclamation mark key.           |
| `Input.KEY_DBLAPOSTROPHE`           | Double apostrophe key.          |
| `Input.KEY_HASH`                    | Hash key.                       |
| `Input.KEY_DOLLAR`                  | Dollar key.                     |
| `Input.KEY_PERCENT`                 | Percent key.                    |
| `Input.KEY_AMPERSAND`               | Ampersand key.                  |
| `Input.KEY_APOSTROPHE`              | Apostrophe key.                 |
| `Input.KEY_LEFTPAREN`               | Left parenthesis key.           |
| `Input.KEY_RIGHTPAREN`              | Right parenthesis key.          |
| `Input.KEY_ASTERISK`                | Asterisk key.                   |
| `Input.KEY_PLUS`                    | Plus key.                       |
| `Input.KEY_COMMA`                   | Comma key.                      |
| `Input.KEY_MINUS`                   | Minus key.                      |
| `Input.KEY_PERIOD`                  | Period key.                     |
| `Input.KEY_SLASH`                   | Slash key.                      |
| `Input.KEY_0` – `Input.KEY_9`       | Number keys 0 through 9.        |
| `Input.KEY_COLON`                   | Colon key.                      |
| `Input.KEY_SEMICOLON`               | Semicolon key.                  |
| `Input.KEY_LESS`                    | Less-than key.                  |
| `Input.KEY_EQUALS`                  | Equals key.                     |
| `Input.KEY_GREATER`                 | Greater-than key.               |
| `Input.KEY_QUESTION`                | Question mark key.              |
| `Input.KEY_AT`                      | At-sign key.                    |
| `Input.KEY_LEFTBRACKET`             | Left bracket key.               |
| `Input.KEY_BACKSLASH`               | Backslash key.                  |
| `Input.KEY_RIGHTBRACKET`            | Right bracket key.              |
| `Input.KEY_CARET`                   | Caret key.                      |
| `Input.KEY_UNDERSCORE`              | Underscore key.                 |
| `Input.KEY_GRAVE`                   | Grave accent key.               |
| `Input.KEY_A` – `Input.KEY_Z`       | Letter keys A through Z.        |
| `Input.KEY_CAPSLOCK`                | Caps Lock key.                  |
| `Input.KEY_F1` – `Input.KEY_F12`    | Function keys F1 through F12.   |
| `Input.KEY_PRINTSCREEN`             | Print Screen key.               |
| `Input.KEY_SCROLLLOCK`              | Scroll Lock key.                |
| `Input.KEY_PAUSE`                   | Pause key.                      |
| `Input.KEY_INSERT`                  | Insert key.                     |
| `Input.KEY_HOME`                    | Home key.                       |
| `Input.KEY_PAGEUP`                  | Page Up key.                    |
| `Input.KEY_DELETE`                  | Delete key.                     |
| `Input.KEY_END`                     | End key.                        |
| `Input.KEY_PAGEDOWN`                | Page Down key.                  |
| `Input.KEY_RIGHT`                   | Right Arrow key.                |
| `Input.KEY_LEFT`                    | Left Arrow key.                 |
| `Input.KEY_DOWN`                    | Down Arrow key.                 |
| `Input.KEY_UP`                      | Up Arrow key.                   |
| `Input.KEY_NUMLOCKCLEAR`            | Num Lock/Clear key.             |
| `Input.KEY_KP_DIVIDE`               | Keypad Divide key.              |
| `Input.KEY_KP_MULTIPLY`             | Keypad Multiply key.            |
| `Input.KEY_KP_MINUS`                | Keypad Minus key.               |
| `Input.KEY_KP_PLUS`                 | Keypad Plus key.                |
| `Input.KEY_KP_ENTER`                | Keypad Enter key.               |
| `Input.KEY_KP_0` – `Input.KEY_KP_9` | Keypad number keys 0 through 9. |
| `Input.KEY_KP_PERIOD`               | Keypad Period key.              |
| `Input.KEY_APPLICATION`             | Application/Menu key.           |
| `Input.KEY_POWER`                   | Power key.                      |
| `Input.KEY_KP_EQUALS`               | Keypad Equals key.              |
| `Input.KEY_LCTRL`                   | Left Ctrl key.                  |
| `Input.KEY_LSHIFT`                  | Left Shift key.                 |
| `Input.KEY_LALT`                    | Left Alt key.                   |
| `Input.KEY_LGUI`                    | Left GUI/Windows/Command key.   |
| `Input.KEY_RCTRL`                   | Right Ctrl key.                 |
| `Input.KEY_RSHIFT`                  | Right Shift key.                |
| `Input.KEY_RALT`                    | Right Alt key.                  |
| `Input.KEY_RGUI`                    | Right GUI/Windows/Command key.  |
| `Input.KEY_MODE`                    | Mode key.                       |
| `Input.KEY_HELP`                    | Help key.                       |
| `Input.KEY_MENU`                    | Menu key.                       |
| `Input.KEY_SELECT`                  | Select key.                     |
| `Input.KEY_STOP`                    | Stop key.                       |
| `Input.KEY_AGAIN`                   | Again key.                      |
| `Input.KEY_UNDO`                    | Undo key.                       |
| `Input.KEY_CUT`                     | Cut key.                        |
| `Input.KEY_COPY`                    | Copy key.                       |
| `Input.KEY_PASTE`                   | Paste key.                      |
| `Input.KEY_FIND`                    | Find key.                       |
| `Input.KEY_MUTE`                    | Mute key.                       |
| `Input.KEY_VOLUMEUP`                | Volume Up key.                  |
| `Input.KEY_VOLUMEDOWN`              | Volume Down key.                |

