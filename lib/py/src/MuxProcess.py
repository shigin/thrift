from thrift.Thrift import *

class TMuxProcessor(TProcessor):
    def __init__(self, processors, default=None):
        """Processor is a dict {'name': processor}"""
        self.__map = processors
        self.__default = default

    def __raise_unknown(self, name, seqid, iprot, oprot):
        iprot.skip(TType.STRUCT)
        iprot.readMessageEnd()
        x = TApplicationException(
                TApplicationException.UNKNOWN_METHOD, 'Unknown function %s' % name)
        oprot.writeMessageBegin(name, TMessageType.EXCEPTION, seqid)
        x.write(oprot)
        oprot.writeMessageEnd()
        oprot.trans.flush()

    def process(self, iprot, oprot):
        name, type, seqid = iprot.readMessageBegin()
        print name
        if '.' in name:
            obj_name, name = name.split('.', 1)
            if obj_name in self.__map:
                obj = self.__map[obj_name]
            else:
                self.__raise_unknown(obj_name, seqid, iprot, oprot)
                return
        else:
            if self.__default:
                obj = self.__default
            else:
                self.__raise_unknown(name, seqid, iprot, oprot)
                return
        if name not in obj._processMap:
            self.__raise_unknown(name, seqid, iprot, oprot)
        else:
            obj._processMap[name](obj, seqid, iprot, oprot)
            return True
