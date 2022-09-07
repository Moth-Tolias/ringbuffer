module ringbuffer;

/**
* a simple template ringbuffer, compatible with @safe, @nogc, pure and nothrow code.
* Authors: Susan
* Date: 2022-02-03
* Licence: AGPL-3.0 or later
* Copyright: Susan, 2022
* special thanks to my good friend flussence, whose advice while making this module was invaluable. <3
*/

struct RingBuffer(DataType, size_t maxLength)
{
	private size_t readIndex; //todo: size_t is overkill in 99.999% of cases
	private size_t writeIndex;
	private DataType[maxLength] data;

	private auto _length() const
	{
		//todo: there is almost certainly a better way to go about this
		if (writeIndex == readIndex)
		{
			return 0;
		}

		immutable write = sanitize(writeIndex);
		immutable read = sanitize(readIndex);

		if (write == read)
		{
			return maxLength;
		}

		if (write > read)
		{
			return write - read;
		}
		else
		{
			return (write + maxLength) - read;
		}
	}

	invariant(_length <= maxLength);

	private auto next(in size_t rhs) @safe @nogc pure nothrow const
	{
		return rhs % (maxLength * 2);
	}

	private auto sanitize(in size_t rhs) const @nogc nothrow pure @safe
	{
		return rhs % maxLength;
	}

	///
	@property auto length() const
	{
		return _length;
	}

	///
	@property auto capacity() const
	{
		return maxLength - length;
	}

	/// assignment
	void opAssign(R)(R rhs)
	in (rhs.length <= maxLength)
	{
		data[0 .. rhs.length] = rhs;
		readIndex = 0;
		writeIndex = rhs.length;
	}

	/// push to buffer
	void push(DataType rhs)
	{
		data[sanitize(writeIndex)] = rhs;
		writeIndex = next(writeIndex + 1);
	}

	/// ditto
	void push(R)(R rhs)
	{
		foreach(DataType d; rhs)
		{
			push(d);
		}
	}

	/// ditto
	void opOpAssign(string op)(DataType rhs)
		if (op == "~")
	in (length + 1 <= maxLength)
	{
		push(rhs);
	}

	/// ditto
	void opOpAssign(string op)(in DataType[] rhs)
		if (op == "~")
	in (length + rhs.length <= maxLength)
	{
		push(rhs);
	}

	/// retrieve item from buffer (fifo)
	DataType shift()
	in (length > 0)
	{
		auto result = data[sanitize(readIndex)];
		readIndex = next(readIndex + 1);
		return result;
	}

	/// retrieve item from buffer (lifo)
	DataType pop()
	in (length > 0)
	{
		writeIndex = next(writeIndex - 1);
		return data[sanitize(writeIndex)];
	}

	/// empty the buffer
	void clear()
	{
		data[] = DataType.init;
		writeIndex = readIndex;
	}

	/// range interface
	auto opIndex() const
	{
		return RingBufferRangeInterface!DataType(data[], readIndex, length);
	}
}

/// example
@safe @nogc nothrow pure unittest
{
	RingBuffer!(int, 5) buff;
	buff.push(69);
	buff ~= 420; // equivilent to the push syntax
	assert(buff.shift == 69);
	assert(buff.shift == 420);

	import std.array : staticArray;
	import std.range : iota;
	immutable int[5] temp = staticArray!(iota(5));

	buff.push(temp); // multiple items may be pushed in a single call

	assert(buff.length == 5);
	assert(buff.capacity == 0);

	assert(buff.pop == 4);

	assert(buff.length == 4);
	assert(buff.capacity == 1);

	buff.clear();

	assert(buff.length == 0);
	assert(buff.capacity == 5);
}

private struct RingBufferRangeInterface(DataType)
{
	private const(DataType[]) source;
	private size_t startIndex;
	private size_t length;

	@disable this();

	package this(in DataType[] source, in size_t startIndex, in size_t length)
	{
		this.source = source;
		this.startIndex = startIndex;
		this.length = length;
	}

	bool empty() const
	{
		return length == 0;
	}

	auto front()
	{
		return source[startIndex % source.length];
	}

	void popFront()
	{
		++startIndex;
		--length;
	}
}

@safe @nogc nothrow pure unittest
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
	assert(foo.length == 8); //not empty. a nasty bug.
	assert(foo.capacity == 0);
	assert(foo.shift == 1);

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

	immutable bar = foo;

	// range test
	int i;
	foreach(val; bar)
	{
		switch(i)
		{
			case 0: assert(val == 97); break;
			case 1: assert(val == 98); break;
			case 2: assert(val == 99); break;
			default: assert(false);
		}

		++i;
	}
}

nothrow pure @safe unittest
{
	class C
	{
		int field;
	}

	RingBuffer!(C, 6) foo;
	assert(foo.length == 0);
	assert(foo.capacity == 6);

	C c = new C;

	foo.push(c);
	assert(foo.shift is c);
	foo.push(c);
	assert(foo.pop is c);

	foo.clear;

	foreach(i; 0 .. foo.capacity)
	{
		auto temp = new C;
		temp.field = cast(int)i;
		foo.push(temp);
	}

	import std.range: enumerate;
	foreach(i, temp; foo[].enumerate(0))
	{
		assert(foo.shift.field == i);
	}
}
