package src;

class Resource<T> {
	public var resource:T;
	public var identifier:String;

	var referenceCount:Int = 0;
	var resourceMap:Map<String, Resource<T>>;
	var disposeFunc:T->Void;

	public function new(resource:T, identifier:String, resList:Map<String, Resource<T>>, disposeFunc:T->Void) {
		this.resource = resource;
		this.resourceMap = resList;
		this.disposeFunc = disposeFunc;
		this.identifier = identifier;
	}

	public function acquire() {
		this.referenceCount++;
		trace('Acquiring Resource ${this.identifier}: ${this.referenceCount}');
	}

	public function release() {
		this.referenceCount--;
		if (this.referenceCount == 0) {
			disposeFunc(this.resource);
			this.resourceMap.remove(this.identifier);
			trace('Releasing Resource ${this.identifier}');
		}
	}
}
