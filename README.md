# ringbuffer
a simple ringbuffer template, compatible with `@safe`, `@nogc`, `pure` and `nothrow` code.

## usage
ringbuffer implements the following methods and properties:

### `push`
adds an element to the start of the buffer.

### `pop`
returns the element at the end of the buffer, and removes it.

### `shift`
returns the element at the start of the buffer, and removes it.

### `unshift`
adds an element to the end of the buffer.

### `clear`
empties the array.

### `length`
returns the number of elements currently in the buffer.

### `capacity`
returns how many elements may be pushed to the array; that is, the number of free slots in the buffer.

in addition to these, [the range interface](https://dlang.org/spec/statement.html#foreach-with-ranges) is also implemented.

## example
```d
void main() @safe @nogc nothrow
{
	RingBuffer!(int, 5) buff;
	buff.push(69);
	buff ~= 420; // equivalent to the push syntax
	assert(buff.shift == 69);
	assert(buff.shift == 420);

	import std.array: staticArray;
	import std.range: iota;

	immutable int[5] temp = staticArray!(iota(5));

	buff.push(temp); // multiple items may be pushed in a single call

	assert(buff.length == 5);
	assert(buff.capacity == 0);

	assert(buff.pop == 4);

	assert(buff.length == 4);
	assert(buff.capacity == 1);

	buff.unshift(666);
	assert(buff.shift == 666);

	buff.clear();

	assert(buff.length == 0);
	assert(buff.capacity == 5);
}
```

## licence
AGPL-3.0 or later
