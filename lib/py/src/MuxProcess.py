import time
from thrift.Thrift import *

class TMuxProcessor(TProcessor):
    def __init__(self, processors=None, default=None):
        """Processor is a dict {'name': processor}"""
        self.__map = processors or {}
        self.__default = default
        self._queries = 0
        self._time = 0.0
        self._errors = 0
        self._processMap = dict(queries=1,
                                time=2,
                                errors=3)

    def register_processor(self, name, processor, default=False):
        self.__map[name] = processor
        if default:
            self.__default = processor

    def register_stat(self):
        self.__map['_stat'] = self

    def __raise_unknown(self, name, seqid, iprot, oprot):
        self._errors += 1
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
            start = time.time()
            self._queries += 1
            obj._processMap[name](obj, seqid, iprot, oprot)
            self._time += time.time() - start
            return True

