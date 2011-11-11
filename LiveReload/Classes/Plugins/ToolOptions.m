
#import "ToolOptions.h"

#import "Compiler.h"
#import "Project.h"
#import "CompilationOptions.h"
#import "UIBuilder.h"



@interface ToolOption() {
@protected
    Compiler              *_compiler;
    Project               *_project;
    NSDictionary          *_info;

    NSString              *_identifier;
}

- (id)initWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo;

- (void)parse;

@property(nonatomic, retain) id storedValue;
@property(nonatomic, readonly) id currentValue;

- (id)defaultValue; // subclasses must override
- (id)newValue;     // subclasses must override
- (void)updateNewValue;

@end



@interface CheckBoxToolOption : ToolOption
@end



@interface SelectToolOption : ToolOption
@end



@interface EditToolOption : ToolOption
@end



Class ToolOptionClassByType(NSString *type) {
    if ([type isEqualToString:@"checkbox"]) {
        return [CheckBoxToolOption class];
    } else if ([type isEqualToString:@"select"]) {
        return [SelectToolOption class];
    } else if ([type isEqualToString:@"edit"]) {
        return [EditToolOption class];
    } else {
        return nil;
    }
}



@implementation ToolOption

@synthesize identifier=_identifier;


#pragma mark - Init/dealloc

+ (ToolOption *)toolOptionWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo {
    NSString *type = [optionInfo objectForKey:@"Type"];
    Class klass = ToolOptionClassByType(type);
    if (klass) {
        return [[[klass alloc] initWithCompiler:compiler project:project optionInfo:optionInfo] autorelease];
    } else {
        return nil;
    }
}

- (id)initWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo {
    self = [super init];
    if (self) {
        _compiler = [compiler retain];
        _project = [project retain];
        _info = [optionInfo copy];

        _identifier = [optionInfo objectForKey:@"Id"];

        [self parse];
    }
    return self;
}

- (void)dealloc {
    [_compiler release], _compiler = nil;
    [_project release], _project = nil;
    [_info release], _info = nil;
    [_identifier release], _identifier = nil;
    [super dealloc];
}


#pragma mark - Values

- (id)storedValue {
    CompilationOptions *options = [_project optionsForCompiler:_compiler create:NO];
    return [options valueForOptionIdentifier:_identifier];
}

- (void)setStoredValue:(id)value {
    CompilationOptions *options = [_project optionsForCompiler:_compiler create:YES];
    [options setValue:value forOptionIdentifier:_identifier];
}

- (id)currentValue {
    return self.storedValue ?: self.defaultValue;
}

- (id)defaultValue {
    NSAssert(NO, @"Must implement defaultValue");
    return nil;
}

- (id)newValue {
    NSAssert(NO, @"Must implement newValue");
    return nil;
}

- (void)updateNewValue {
    [self setStoredValue:[self newValue]];
}


#pragma mark - Rendering

- (void)renderControlWithBuilder:(UIBuilder *)builder {
}

- (void)renderWithBuilder:(UIBuilder *)builder {
    [self renderControlWithBuilder:builder];
    NSString *label = [_info objectForKey:@"Label"];
    if (label.length > 0) {
        [builder addLabel:label];
    }
}


#pragma mark - Stubs

- (void)parse {
}

- (void)save {
    [self updateNewValue];
}

@end



#pragma mark - Check Box

@implementation CheckBoxToolOption {
    NSString              *_title;

    NSButton              *_view;
}

- (void)parse {
    _title = [[_info objectForKey:@"Title"] copy];
}

- (void)dealloc {
    [_title release], _title = nil;
    [_view release], _view = nil;
    [super dealloc];
}

- (id)defaultValue {
    return [NSNumber numberWithBool:NO];
}

- (id)newValue {
    return [NSNumber numberWithBool:_view.state == NSOnState];
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [[builder addCheckboxWithTitle:_title] retain];
    [_view setTarget:self];
    [_view setAction:@selector(checkBoxClicked:)];
    _view.state = [self.currentValue boolValue] ? NSOnState : NSOffState;
}

- (IBAction)checkBoxClicked:(id)sender {
    [self updateNewValue];
}

@end



#pragma mark - Select

@implementation SelectToolOption {
    NSArray               *_items;

    NSPopUpButton         *_view;
}

- (void)parse {
    _items = [[_info objectForKey:@"Items"] copy];
}

- (void)dealloc {
    [_items release], _items = nil;
    [_view release], _view = nil;
    [super dealloc];
}

- (id)defaultValue {
    return [[_items objectAtIndex:0] objectForKey:@"Id"];
}

- (id)newValue {
    NSInteger index = [_view indexOfSelectedItem];
    if (index == -1)
        return self.defaultValue;
    return [[_items objectAtIndex:index] objectForKey:@"Id"];
}

- (NSInteger)indexOfItemWithIdentifier:(NSString *)itemIdentifier {
    NSInteger index = 0;
    for (NSDictionary *itemInfo in _items) {
        if ([[itemInfo objectForKey:@"Id"] isEqualToString:itemIdentifier]) {
            return index;
        }
        ++index;
    }
    return -1;
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [[builder addPopUpButton] retain];
    [_view addItemsWithTitles:[_items valueForKeyPath:@"Title"]];
    [_view selectItemAtIndex:[self indexOfItemWithIdentifier:self.currentValue]];
}

@end



#pragma mark - Edit

@implementation EditToolOption {
    NSString              *_placeholder;

    NSTextField           *_view;
}

- (void)parse {
    _placeholder = [[_info objectForKey:@"Placeholder"] copy];
}

- (void)dealloc {
    [_placeholder release], _placeholder = nil;
    [_view release], _view = nil;
    [super dealloc];
}

- (id)defaultValue {
    return @"";
}

- (id)newValue {
    return  _view.stringValue;
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [[builder addTextField] retain];
    if (_placeholder.length > 0) {
        [_view.cell setPlaceholderString:_placeholder];
    }
    _view.stringValue = self.currentValue;
}

@end