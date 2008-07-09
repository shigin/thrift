from thrift.Thrift import *
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
try:
  from thrift.protocol import fastbinary
except:
  fastbinary = None

def write_adv_helper(oprot, ftype, type_args, value):
  if ftype == TType.MAP:
    # XXX TODO handle complex type
    ktype, kspec, vtype, vspec = type_args
    oprot.writeMapBegin(ktype, vtype, len(value))
    for k, v in value.items():
      write_helper(oprot, ktype, kspec, k)
      write_helper(oprot, vtype, vspec, v)
    oprot.writeMapEnd()
  elif ftype in (TType.LIST, TType.SET):
    if ftype == TType.LIST:
      begin = oprot.writeListBegin
      end = oprot.writeListEnd
    else:
      begin = oprot.writeSetBegin
      end = oprot.writeSetEnd
    xtype, xspec = type_args
    begin(xtype, len(value))
    for k in value:
      write_helper(oprot, xtype, xspec, k)
    end()
  elif ftype == TType.STRUCT:
    value.write(oprot)
  else:
    raise "XXX: hey, it's %d type" % ftype

def write_helper(oprot, ftype, type_args, value):
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
    write_adv_helper(oprot, ftype, type_args, value)

def reader_helper(iprot, ftype, type_args):
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
   class_, _ = type_args
   result = class_()
   result.read(iprot)
   return result
  elif ftype == TType.MAP:
    # XXX TODO: support complex types
    ktype, vtype, size = iprot.readMapBegin()
    kstype, kspec, vstype, vspec = type_args
    assert ktype == kstype
    assert vtype == vstype
    result = {}
    for i in range(size):
      key   = reader_helper(iprot, ktype, kspec)
      value = reader_helper(iprot, vtype, vspec)
      result[key] = value
    iprot.readMapEnd()
    return result
  elif ftype == TType.SET:
    etype, size = iprot.readSetBegin()
    stype, spec = type_args
    result = set()
    for i in xrange(size):
      result.update([reader_helper(iprot, etype, spec)])
    iprot.readSetEnd()
    return result
  elif ftype == TType.LIST:
    etype, size = iprot.readListBegin()
    stype, spec = type_args
    result = []
    for i in xrange(size):
      result.append(reader_helper(iprot, etype, spec))
    iprot.readListEnd()
    return result
  raise "XXX"

    
# new style class has __name__ property
class ThriftStruct(object):
  """Parent of all structure.
  
  Child MUST specify thrift_spec!
  
   (num, type, name, type_args, default)
  or cached:
   num: (type, name, type_args, default)
   
  """
  def __init__(self, d=None):
    # TODO: guard it with mutex
    class_ = type(self)
    if not hasattr(class_, 'cached'):
      class_.cached = {}
      for specs in self.thrift_spec:
        if specs:
          class_.cached[specs[0]] = specs[1:]
    for  _, name, _, default in self.cached.values():
        setattr(self, name, default)
    if d: # it can be None
      for name, value in d.items():
        setattr(self, name, value)

  def read(self, iprot):
    if fastbinary and self.thrift_spec is not None:
      if isinstance(iprot, TBinaryProtocol.TBinaryProtocolAccelerated):
        fastbinary.decode_binary(self, iprot.trans, (self.__class__, self.thrift_spec))
        return

    iprot.readStructBegin()
    while True:
      fname, ftype, fid = iprot.readFieldBegin()
      if ftype == TType.STOP:
        break
      else:
        if fid in self.cached:
          stype, sname, type_args, default = self.cached[fid]
        else:
          iprot.skip(ftype)
          continue
        if stype == ftype:
          setattr(self, sname, reader_helper(iprot, stype, type_args))
        else:
          iprot.skip(ftype)
    iprot.readFieldEnd()
    iprot.readStructEnd()

  def write(self, oprot):
    if fastbinary and self.thrift_spec is not None:
      if isinstance(oprot, TBinaryProtocol.TBinaryProtocolAccelerated):
        spec = self.__class__, self.thrift_spec
        oprot.trans.write(fastbinary.encode_binary(self, spec))
        return

    oprot.writeStructBegin(self.__class__.__name__)
    for fid, spec in self.cached.items():
      ftype, fname, type_args, default = spec
      if hasattr(self, fname):
        value = getattr(self, fname)
        oprot.writeFieldBegin(fname, ftype, fid)
        write_helper(oprot, ftype, type_args, value)
        oprot.writeFieldEnd()
    oprot.writeFieldStop()
    oprot.writeStructEnd()
