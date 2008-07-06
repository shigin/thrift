from thrift.Thrift import *
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
try:
  from thrift.protocol import fastbinary
except:
  fastbinary = None

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
    assert isinstance(d, dict)
    self.vars = vars
    # TODO: guard this with mutex
    class_ = type(self)
    if hasattr(class_, 'cached'):
      return
    class_.cached = {}
    for x in self.thrift_spec:
      class_.cached[x[0]] = x[1:]

  def write(self, iprot):
    if fastbinary and isinstance(oprot, TBinaryProtocol.TBinaryProtocolAccelerated):
      spec = self.__class__, self.thrift_spec
      oprot.trans.write(fastbinary.encode_binary(self, spec))
      return

   iprot.readStructBegin()
   while True:
    fname, ftype, fid = iprot.readFieldBegin()
    if ftype == TType.STOP:
      break
    else:
      stype, sname, type_args, default = self.cached[fid]
      if stype == ftype:
        if stype:
          class_, spec = type_args
          self.vars[sname] = class_()
          self.vars[sname].read()
        else:
          self.vars[sname] = reader_helper(iprot, stype)
      else:
        iprot.skip(ftype)
    iprot.readFieldEnd()
  iprot.readStructEnd()

  def __write(self, oprot):
    if fastbinary and isinstance(oprot, TBinaryProtocol.TBinaryProtocolAccelerated):
      spec = self.__class__, self.thrift_spec
      oprot.trans.write(fastbinary.encode_binary(self, spec))
      return
    oprot.writeStructBegin(self.__class__.__name__)
    for name, value in self.vars.items():
      # XXX
      pass
    oprot.writeFieldStop()
    oprot.writeStructEnd()
