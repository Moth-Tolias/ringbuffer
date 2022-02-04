module ringbuffer;

/**
* a simple @safe and @nogc-compatible template ringbuffer.
* Authors: Susan
* Date: 2022-02-03
* Licence: AGPL-3.0 or later
* Copyright: Susan, 2022
* special thanks to my good friend flussence, whose advice while making this module was invaluable. <3
*/

struct RingBuffer(DataType, size_t maxLength)
{
	private size_t readIndex;
	private size_t writeIndex;
	private DataType[maxLength] data;

	private auto _length() @safe @nogc pure nothrow const
	{
		immutable write = next(writeIndex);
		immutable read = next(readIndex);
		if (read > write)
		{
			return (write + maxLength) - read;
		}
		return write - read;
	}

	invariant(_length <= maxLength);

	private auto next(in size_t rhs) @safe @nogc pure nothrow const
	{
		import std.math.traits : isPowerOf2;
		static if (isPowerOf2(maxLength))
		{
			return rhs & (maxLength - 1);
		}
		else
		{
			return rhs % maxLength;
		}
	}

	///
	@property auto length() @safe @nogc pure nothrow const
	{
		return _length;
	}

	///
	@property auto capacity() @safe @nogc pure nothrow const
	{
		return maxLength - length;
	}

	/// assignment
	void opAssign(in DataType[] rhs) @safe @nogc nothrow pure
	in (rhs.length <= maxLength)
	{
		data[0 .. rhs.length] = rhs;
		readIndex = 0;
		writeIndex = rhs.length;
	}

	/// push to buffer
	void push(in DataType rhs) @safe @nogc pure nothrow
	{
		data[writeIndex] = rhs;
		writeIndex = next(writeIndex + 1);
	}

	/// ditto
	void push(in DataType[] rhs) @safe @nogc pure nothrow
	{
		foreach(DataType d; rhs)
		{
			push(d);
		}
	}

	/// ditto
	void opOpAssign(string op)(in DataType rhs) @safe @nogc nothrow pure
		if (op == "~")
	in (length + 1 <= maxLength)
	{
		push(rhs);
	}

	/// ditto
	void opOpAssign(string op)(in DataType[] rhs) @safe @nogc nothrow pure
		if (op == "~")
	in (length + rhs.length <= maxLength)
	{
		push(rhs);
	}

	/// retrieve item from buffer (fifo)
	DataType shift() @safe @nogc nothrow pure
	in (length > 0)
	{
		immutable result = data[readIndex];
		readIndex = next(readIndex + 1);
		return result;
	}

	/// retrieve item from buffer (lifo)
	DataType pop() @safe @nogc nothrow pure
	in (length > 0)
	{
		writeIndex = next(writeIndex - 1);
		return data[writeIndex];
	}

	/// empty the buffer
	void clear() @safe @nogc nothrow pure
	{
		data[] = DataType.init;
		writeIndex = readIndex;
	}

	/// range interface
	bool empty() @safe @nogc nothrow pure const
	{
		return length > 0;
	}

	/// ditto
	DataType front() @safe @nogc nothrow const pure
	{
		return data[readIndex];
	}

	/// ditto
	void popFront() @safe @nogc nothrow pure
	{
		shift();
	}
}

@safe @nogc nothrow unittest
{
	RingBuffer!(int, 8) foo;
	assert(foo.length == 0);
	assert(foo.capacity == 8);

	foo.push(0); //0
	assert(foo.length == 1);
	assert(foo.capacity == 7);

	import std.array : staticArray;
	import std.range : iota;
	immutable int[5] temp = staticArray!(iota(5));

	foo ~= temp[1 .. 3]; //0, 1, 2
	foo.push(temp[3 .. 5]); //0, 1, 2, 3, 4
	assert(foo.length == 5);
	assert(foo.capacity == 3);

	assert(foo.shift == 0); //1, 2, 3, 4
	assert(foo.pop == 4); //1, 2, 3

	assert(foo.length == 3);
	assert(foo.capacity == 5);

	foo.push(temp); //1, 2, 3, 0, 1, 2, 3, 4

	foo.clear();
	assert(foo.length == 0);
	assert(foo.capacity == 8);

	foo ~= temp;
	assert(foo.length == temp.length);
	assert(foo.shift == 0);
	assert(foo.pop == 4);
	assert(foo.length == 3);
	assert(foo.capacity == 5);

	foo = temp;
	assert(foo.shift == 0);
	assert(foo.pop == 4);
	assert(foo.length == 3);
	assert(foo.capacity == 5);

	foreach(i; 0 .. 100) //one last stomp
	{
		foo.push(i);
		foo.shift;
	}
}
