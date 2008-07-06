from thrift.Thrift import *
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
try:
  from thrift.protocol import fastbinary
except:
  fastbinary = None

def write_helper(oprot, ftype, value):
  # copy-paste from TProtocol.skip
  if ftype == TType.STOP:
    raise "XXX"
  elif ftype == TType.BOOL:
    oprot.writeBool(value)
  elif ftype == TType.BYTE:
    oprot.writeByte(value)
  elif ftype == TType.I16:
    oprot.writeI16(value)
  elif ftype == TType.I32:
    oprot.writeI32(value)
  elif ftype == TType.I64:
    oprot.writeI64(value)
  elif ftype == TType.DOUBLE:
    oprot.writeDouble(value)
  elif ftype == TType.STRING:
    oprot.writeString(value)
  else:
    raise "XXX: hey, it's %d type" % ftype

def reader_helper(iprot, ftype):
  # copy-paste from TProtocol.skip
  if ftype == TType.STOP:
    raise "XXX"
  elif ftype == TType.BOOL:
    return iprot.readBool()
  elif ftype == TType.BYTE:
    return iprot.readByte()
  elif ftype == TType.I16:
    return iprot.readI16()
  elif ftype == TType.I32:
    return iprot.readI32()
  elif ftype == TType.I64:
    return iprot.readI64()
  elif ftype == TType.DOUBLE:
    return iprot.readDouble()
  elif ftype == TType.STRING:
    return iprot.readString()
  elif ftype == TType.STRUCT:
    raise "XXX"
  elif ftype == TType.MAP:
    ktype, vtype, size = iprot.readMapBegin()
    result = {}
    for i in range(size):
      key = iprot.skip(ktype)
      value = iprot.skip(vtype)
      result[key] = value
    iprot.readMapEnd()
    return result
  elif ftype == TType.SET:
    etype, size = iprot.readSetBegin()
    result = set()
    for i in xrange(size):
      result.append(reader_helper(iprot, etype))
    iprot.readSetEnd()
    return result
  elif ftype == TType.LIST:
    etype, size = iprot.readListBegin()
    result = []
    for i in xrange(size):
      result.append(reader_helper(iprot, etype))
    iprot.readListEnd()
    return result
  raise "XXX"

# new style class has __name__ property
class ThriftStruct(object):
  """Parent of all structure.
  
  Child MUST specify thrift_spec!
  
   (num, type, typeargs, default)
  """
  def __init__(self, vars=None):
    assert self.thrift_spec
    # it may be bad
    if vars:
      assert isinstance(vars, dict)
      for name, value in vars.items():
        setattr(self, name, value)
    # TODO: guard it with mutex
    class_ = type(self)
    if hasattr(class_, 'cached'):
      return
    class_.cached = {}
    for x in self.thrift_spec:
      if x:
        class_.cached[x[0]] = x[1:]

  def read(self, iprot):
    if fastbinary and isinstance(iprot, TBinaryProtocol.TBinaryProtocolAccelerated):
      fastbinary.decode_binary(self, iprot.trans, (self.__class__, self.thrift_spec))
      return

    iprot.readStructBegin()
    while True:
      fname, ftype, fid = iprot.readFieldBegin()
      if ftype == TType.STOP:
        break
      else:
        stype, sname, type_args, default = self.cached[fid]
        if stype == ftype:
          if ftype == TType.STRUCT:
            class_, spec = type_args
            result = class_()
            result.read()
            setattr(self, sname, result)
          else:
            setattr(self, sname, reader_helper(iprot, stype))
        else:
          iprot.skip(ftype)
    iprot.readFieldEnd()
    iprot.readStructEnd()

  def write(self, oprot):
    if fastbinary and isinstance(oprot, TBinaryProtocol.TBinaryProtocolAccelerated):
      spec = self.__class__, self.thrift_spec
      oprot.trans.write(fastbinary.encode_binary(self, spec))
      return

    oprot.writeStructBegin(self.__class__.__name__)
    for spec in self.thrift_spec:
      if spec is None:
        continue
      fid, ftype, fname, type_args, default = spec
      value = getattr(self, fname, default)
      if value is not None: # it's bad idea to skip [] as None
        oprot.writeFieldBegin(fname, ftype, fid)
        if ftype in (TType.STRUCT, TType.SET, TType.MAP, TType.LIST):
          raise "XXX"
        else:
          write_helper(oprot, ftype, value)
        oprot.writeFieldEnd()
    oprot.writeFieldStop()
    oprot.writeStructEnd()
